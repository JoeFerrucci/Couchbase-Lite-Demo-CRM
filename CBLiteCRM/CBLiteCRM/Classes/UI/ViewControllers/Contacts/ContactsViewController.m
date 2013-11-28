//
//  ContactsViewController.m
//  CBLiteCRM
//
//  Created by Danil on 26/11/13.
//  Copyright (c) 2013 Danil. All rights reserved.
//

#import "ContactsViewController.h"
#import "ContactDetailsViewController.h"
#import "DataStore.h"
#import "Contact.h"

@interface ContactsViewController (){
    CBLUITableSource* dataSource;
    Contact* selectedContact;
}
@end

@implementation ContactsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    dataSource = [CBLUITableSource new];
    dataSource.tableView = self.tableView;
    self.tableView.dataSource = dataSource;
    [self updateQuery];
}

- (void) updateQuery {
    dataSource.query = [[[DataStore sharedInstance] queryContacts] asLiveQuery];
}

// Called when a row is selected/touched.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    CBLQueryRow *row = [dataSource rowAtIndex:indexPath.row];
    selectedContact = [Contact modelForDocument: row.document];
    
    [self performSegueWithIdentifier:@"presentContactDetails" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([segue.destinationViewController isKindOfClass:[ContactDetailsViewController class]]){
        ContactDetailsViewController* vc = segue.destinationViewController;
        vc.currentContact = selectedContact;
    }
}

@end