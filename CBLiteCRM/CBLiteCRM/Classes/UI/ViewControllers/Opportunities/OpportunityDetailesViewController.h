//
//  OpportunityDetailesViewController.h
//  CBLiteCRM
//
//  Created by Danil on 29/11/13.
//  Copyright (c) 2013 Couchbase. All rights reserved.
//

#import "TextFieldsViewController.h"
#import "UIViewController+ReadOnlyOrWriteMode.h"

@class Opportunity;
@interface OpportunityDetailesViewController : TextFieldsViewController<EditableViewControllers>

@property(nonatomic, strong) Opportunity* currentOpport;
@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UITextField *stageField;
@property (weak, nonatomic) IBOutlet UITextField *dateField;
@property (weak, nonatomic) IBOutlet UITextField *revenueField;
@property (weak, nonatomic) IBOutlet UITextField *winField;
@property (weak, nonatomic) IBOutlet UIView *buttonsView;
@property (weak, nonatomic) IBOutlet UIButton *customerButton;
@property (weak, nonatomic) IBOutlet UIButton *customerDetailsButton;
@property (weak, nonatomic) IBOutlet UIButton *contactsButton;

- (IBAction)back:(id)sender;
- (IBAction)saveItem:(id)sender;
- (IBAction)deleteItem:(id)sender;
- (IBAction)customerDetails:(id)sender;
@end
