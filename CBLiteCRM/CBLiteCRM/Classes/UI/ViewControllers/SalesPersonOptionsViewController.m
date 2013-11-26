//
//  SalesPersonOptionsViewController.m
//  CBLiteCRM
//
//  Created by Ruslan on 11/26/13.
//  Copyright (c) 2013 Danil. All rights reserved.
//

#import "SalesPersonOptionsViewController.h"
#import "SalesPerson.h"

@interface SalesPersonOptionsViewController ()

@property (strong, nonatomic) IBOutlet UILabel *name;

@end

@implementation SalesPersonOptionsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {}
    return self;
}

-(void)viewWillAppear:(BOOL)animated
{
    [self loadUserData];
}

- (void)loadUserData
{
    _name.text = self.salesPerson.email;
    [_name sizeToFit];
}

@end
