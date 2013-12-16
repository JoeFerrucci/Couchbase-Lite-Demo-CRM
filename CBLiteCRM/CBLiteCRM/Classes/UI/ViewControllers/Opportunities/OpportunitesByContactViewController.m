//
//  OportunitesByContactViewController.m
//  CBLiteCRM
//
//  Created by Ruslan on 12/10/13.
//  Copyright (c) 2013 Danil. All rights reserved.
//

#import "OpportunitesByContactViewController.h"

#import "DataStore.h"
#import "ContactOpportunity.h"
#import "OpportunityContactStore.h"
#import "Opportunity.h"
#import "Customer.h"

@interface OpportunitesByContactViewController ()
@property (nonatomic, weak) OpportunityContactStore *store;
@end

@implementation OpportunitesByContactViewController

- (void) updateQuery
{
    self.store = [DataStore sharedInstance].opportunityContactStore;
    if (self.filteringContact)
        self.dataSource.query = [[(OpportunityContactStore*)self.store queryOpportunitiesForContact:self.filteringContact] asLiveQuery];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    self.selectedCellData = [self contactOpportunityForPath:indexPath].opportunity;
    [self performSegueWithIdentifier:@"opportDetails" sender:tableView];
}

- (ContactOpportunity*)contactOpportunityForPath:(NSIndexPath*)indexPath
{
    CBLQueryRow *row = [self.currentSource rowAtIndex:indexPath.row];
    return [ContactOpportunity modelForDocument: row.document];
}

-(UITableViewCell *)couchTableSource:(CBLUITableSource *)source cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[source tableView] dequeueReusableCellWithIdentifier:@"OpportunityCell"];
    if (!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"OpportunityCell"];

    ContactOpportunity *ctOpp = [ContactOpportunity modelForDocument:[source.rows[indexPath.row] document]];
    Opportunity* opp = ctOpp.opportunity;
    cell.textLabel.text = [opp getValueOfProperty:@"title"];
    cell.detailTextLabel.text = opp.customer.companyName;
    return cell;
}

-(void)filterContentForSearchText:(NSString *)searchText scope:(NSString *)scope
{
    NSError *err;
    CBLQuery *query = [(OpportunityContactStore*)self.store filteredQuery];
    CBLQueryEnumerator *enumer = [self.dataSource.query rows:&err];

    NSMutableArray *matches = [NSMutableArray new];
    for (NSUInteger i = 0; i < enumer.count; i++) {
        CBLQueryRow *row = [self.dataSource rowAtIndex:i];
        ContactOpportunity *ctOpp = [ContactOpportunity modelForDocument:row.document];
        NSString* searchableString = ctOpp.opportunity.title;
        if ([searchableString rangeOfString:searchText options:NSCaseInsensitiveSearch].location != NSNotFound)
            [matches addObject:ctOpp.document.documentID];
    }
    query.keys = matches;
    self.filteredDataSource.query = [query asLiveQuery];
}

@end
