//
//  ContactDetailsViewController.m
//  CBLiteCRM
//
//  Created by Danil on 26/11/13.
//  Copyright (c) 2013 Couchbase. All rights reserved.
//

//UI
#import "ContactDetailsViewController.h"
#import "ImagePickerAngel.h"
#import "CustomersViewController.h"
#import "OpportunitesByContactViewController.h"
#import "ContactsByOpportunityViewController.h"
#import "UIImage+Tools.h"
#import "CustomerDetailsViewController.h"

//Data
#import "DataStore.h"
#import "ContactsStore.h"
#import "Contact.h"
#import "Customer.h"
#import "CBLModelDeleteHelper.h"

#define kContactDetailsViewControllerImageSize 300

typedef void (^ValidationBlock)(BOOL isValid, NSString *msg);

@interface ContactDetailsViewController ()
<UITextFieldDelegate,UIAlertViewDelegate>
{
    UIImage* selectedImage;
    UITapGestureRecognizer* photoTapRecognizer;
    ImagePickerAngel * imagePickerAngel;
    Customer *selectedCustomer;
    id currentFirstResponder;
    CBLModelDeleteHelper* deleteHelper;
}

@end

@implementation ContactDetailsViewController
@synthesize deleteButton, textFields, buttons;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupPhotoView];
    [self setupMode];
    deleteHelper = [CBLModelDeleteHelper new];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self loadInfoForContact:self.currentContact];
}

- (void)setupMode
{
    BOOL editMode;
    if(self.currentContact)
        editMode = NO;
    else
        editMode = YES;
    [self setEditMode:editMode];
}

- (void)editModeChanged:(BOOL)editMode {
    self.buttonsView.hidden = editMode;
}

- (void)loadInfoForContact:(Contact*)ct{
    self.buttonsView.hidden = !ct;
    if(ct)
    {
        self.nameField.text = ct.name;
        [self.companyButton setTitle:[self titleForCustomer:[self actualCustomer]] forState:UIControlStateNormal];
        self.detailsButton.enabled = [self actualCustomer] != nil;
        self.positionField.text = ct.position;
        self.phoneField.text = ct.phoneNumber;
        self.mailField.text = ct.email;
        self.addressField.text = ct.address;
        self.photoView.image = [self photoImageForContact:ct];
        selectedImage = [self photoImageForContact:ct];
    }
}



- (void)setupPhotoView
{
    if(!photoTapRecognizer)
    {
        photoTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapOnPhoto)];
        [self.photoView addGestureRecognizer:photoTapRecognizer];
        self.photoView.userInteractionEnabled = YES;
    }
}

#pragma mark - Photo logic

- (UIImage*)photoImageForContact:(Contact*)contact
{
    UIImage * photo = [contact photo];
    
    if(!photo)
        photo = [UIImage imageNamed:@"PhotoPlaceholder"];
    
    return photo;
}

- (void)didTapOnPhoto
{
    if ([self isEditMode]) {
        [currentFirstResponder resignFirstResponder];
        [self pickNewImage];
    }
}

- (void) pickNewImage
{
    if(!imagePickerAngel) {
        imagePickerAngel = [ImagePickerAngel new];
        imagePickerAngel.parentViewController = self;
    }
    imagePickerAngel.onPickedImage = [self createOnPickedImageBlock];
    imagePickerAngel.onDeleteImage = [self createOnDeleteImageBlock];
    [imagePickerAngel presentImagePicker];
}

- (ImagePickerAngelBlock) createOnPickedImageBlock
{
    __weak typeof(self) weakSelf = self;
    return ^(UIImage * image) { [weakSelf setPhotoImage:image]; };
}

- (ImagePickerAngelDeleteBlock) createOnDeleteImageBlock {
    __weak typeof(self) weakSelf = self;
    return ^(void){
        weakSelf.photoView.image = [UIImage imageNamed:@"PhotoPlaceholder"];
        selectedImage = nil;
    };
}

- (void)setPhotoImage:(UIImage*)image
{
    UIImage * scaledImage = [image scaledSquaredImageToSize:kContactDetailsViewControllerImageSize];
    
    self.photoView.image = selectedImage = scaledImage;
}

#pragma mark - Actions

- (IBAction)back:(id)sender {
    self.currentContact = nil;
    if([self.presentingViewController isKindOfClass:[UINavigationController class]]){
        if ([[((UINavigationController*)self.presentingViewController).viewControllers lastObject] isKindOfClass:[ContactsViewController class]])
            [self dismissViewControllerAnimated:YES completion:NULL];
        else{
            [self.navigationController popViewControllerAnimated:YES];
        }
    }else{
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (IBAction)opportunities:(id)sender
{
    [self performSegueWithIdentifier:@"presentOpportunitiesForContact" sender:self];
}

- (IBAction)saveItem:(id)sender {
    if([self.navigationItem.rightBarButtonItem.title isEqualToString:kSaveTitle]){
        [self validateAndSave];
    }else if([self.navigationItem.rightBarButtonItem.title isEqualToString:kEditTitle])
        [self setEditMode:YES];
}

- (IBAction)customerAction {
    if ([self isEditMode])
        [self performSegueWithIdentifier:@"presentCustomers" sender:self];
    else
    if([self actualCustomer])
        [self performSegueWithIdentifier:@"presentMyCustomer" sender:self];
}

- (void)validateAndSave {
    __weak typeof(self) weakSelf = self;
    [self isAllRequiredFieldsValid:^(BOOL isValid, NSString *msg) {
        if(isValid){
            [weakSelf saveContact];
            [weakSelf setEditMode:NO];
        } else {
            [UIAlertView showErrorMessage:msg];
        }
    }];
}

- (void)saveContact {
    Contact* newContact = self.currentContact;
    if(!newContact)
        newContact = [[DataStore sharedInstance].contactsStore createContactWithMailOrReturnExist:self.mailField.text];
    [self updateInfoForContact:newContact];
}

- (DeleteBlock) createOnDeleteBlock {
    __weak typeof(self) weakSelf = self;
    return ^(BOOL shouldDelete){
        if (shouldDelete) {
            [weakSelf dismissViewControllerAnimated:YES completion:^{}];
        }
    };
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[CustomersViewController class]]) {
        CustomersViewController* vc = (CustomersViewController*)segue.destinationViewController;
        [vc setOnSelectCustomer:^(Customer *cust) {
            selectedCustomer = cust;
            if(self.currentContact){
                self.currentContact.customer = cust;
                NSError *error;
                [self.currentContact save:&error];
            }
            [self.companyButton setTitle:[self titleForCustomer:selectedCustomer] forState:UIControlStateNormal];
            self.detailsButton.enabled = selectedCustomer != nil;
        }];
        vc.chooser = YES;
    } else if ([segue.destinationViewController isKindOfClass:[OpportunitesByContactViewController class]]) {
        OpportunitesByContactViewController *vc = (OpportunitesByContactViewController*)segue.destinationViewController;
        vc.navigationItem.rightBarButtonItem = nil;
        vc.filteringContact = self.currentContact;
    } else if([segue.identifier isEqualToString:@"presentMyCustomer"]){
        CustomerDetailsViewController* vc = (CustomerDetailsViewController*)((UINavigationController*)segue.destinationViewController).topViewController;
        vc.currentCustomer = [self actualCustomer];
    }
}

#pragma mark - Fields Validation

- (void)isAllRequiredFieldsValid:(ValidationBlock)result
{
    if ([self.nameField.text isEqualToString:@""])
        result(NO,  @"Name is required\n");
    else
        result(YES, @"");
}

#pragma mark - helpers methods

- (void)updateInfoForContact:(Contact*)ct{
    ct.name = self.nameField.text;
    if(selectedCustomer)
        ct.customer = selectedCustomer;
    ct.position = self.positionField.text;
    ct.phoneNumber = self.phoneField.text;
    ct.address = self.addressField.text;
    ct.opportunities = [self selectedOpportunities];
    ct.email = self.mailField.text;
    if(selectedImage)
        [ct setAttachmentNamed:@"photo" withContentType:@"image/png" content:UIImagePNGRepresentation(selectedImage)];
    else
        [ct removeAttachmentNamed:@"photo"];
    NSError* error;
    if(![ct save:&error])
        NSLog(@"error in save contact: %@", error);
    else
        self.currentContact = ct;
}

-(void)setCurrentContact:(Contact *)currentContact {
    _currentContact = currentContact;
}

- (NSArray*)selectedOpportunities{
    return @[];
}

- (Customer*)actualCustomer{
    Customer* actualCustomer;
    if(self.currentContact)
        actualCustomer = self.currentContact.customer;
    else
        actualCustomer = selectedCustomer;
    return actualCustomer;
}

- (UIImage*)imageFromAttachment:(CBLAttachment*)attach{
    return [UIImage imageWithData:attach.content];
}

- (NSString*) titleForCustomer:(Customer*)customer
{
    if (customer.companyName.length == 0)
        return @"Select Company";
    
    return customer.companyName;
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    currentFirstResponder = textField;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    currentFirstResponder = nil;
    return YES;
}

@end
