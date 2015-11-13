//
//  JKKHomeViewController.m
//  App
//
//  Created by Kevin on 1/25/14.
/* ========================================================================
 *  Copyright 2014 Kyle Cesare, Kevin Hess, Joe Runde, Chadd Armstrong, Chris Heist
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 * ========================================================================
 */

#import "JKKHomeViewController.h"
#import "JKKSetupViewController.h"
#import "JKKCalibrationListViewController.h"

#import "DataStore.h"
#import "ResultEntry.h"
#import "JKKDatabaseManager.h"

@interface JKKHomeViewController ()

@property NSMutableArray* testItems;
@property NSMutableArray* historyItems;

@end

RegressionFactory homeFactory;

@implementation JKKHomeViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [self.testsTable setDataSource:self];
    [self.testsTable setDelegate:self];
    [self.historyTable setDataSource:self];
    [self.historyTable setDelegate:self];
    
    self.historyItems = [[NSMutableArray alloc] init];
    [self populateHistoryTable];
    
    self.testItems = [[NSMutableArray alloc] init];
    [self populateTestTable];
    
    /* sample model
    RegressionFactory::RegressionFactory factory;
    factory.createNew("Sample", "Sample");
    factory.addNewComponent(ModelComponent::LINEAR, 0, 326, ModelComponent::RED);
    factory.addNewComponent(ModelComponent::POINT, 293, 326, ModelComponent::RED);
    
    cv::Mat matrix(5, 3, CV_32F);
    matrix.row(0).at<float>(0) = 40;
    matrix.row(0).at<float>(1) = .00023632315 * 30;
    matrix.row(0).at<float>(2) = 235.61401;
    
    matrix.row(1).at<float>(0) = 100;
    matrix.row(1).at<float>(1) = -0.00077432749 * 30;
    matrix.row(1).at<float>(2) = 227.77617;
    
    matrix.row(2).at<float>(0) = 200;
    matrix.row(2).at<float>(1) = -0.00279011 * 30;
    matrix.row(2).at<float>(2) = 213.48505;
    
    matrix.row(3).at<float>(0) = 300;
    matrix.row(3).at<float>(1) = -0.0048780013 * 30;
    matrix.row(3).at<float>(2) = 189.93724;
    
    matrix.row(4).at<float>(0) = 400;
    matrix.row(4).at<float>(1) = -0.0069368137 * 30;
    matrix.row(4).at<float>(2) = 173.00835;
    
    JKKModel* sampleModel;
    sampleModel = [[JKKModel alloc] initWithModel: factory.getCreatedModel()];
    sampleModel.model->setIndices(3, 2, 1, 0, -1);
    sampleModel.model->superSecretCalibrationOverride(matrix);
    sampleModel.model->dryCalibrate();
    
    [self.testItems addObject:sampleModel];
    [self.testsTable reloadData];
     */
    
    /* Placeholder objects
    JKKTest* test1 = [[JKKTest alloc] initWithName:@"Glucose test"];
    JKKResult* result1 = [[JKKResult alloc] initWithTest:test1];
    result1.value = @42;
    [self.testItems addObject:test1];
    [self.historyItems addObject:result1];
     */
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (void) populateHistoryTable {
    // hessk:generate history items from sqlite database
    
    // TODO: getting rid of all the objects all the time and rereading from the database isn't very efficient...
    [self.historyItems removeAllObjects];
    
    DataStore p = [[JKKDatabaseManager sharedInstance] openDatabase];
    std::vector<ResultEntry> results = p.findAllResultEntries();
    p.close();
    
    JKKResult* currentResult;
    int resultID;
    NSString *name, *subject, *notes, *date, *stats;
    float value;
    // hessk: TODO: dates
    
    for (int i = 0; i < results.size(); i++) {
        resultID = results[i].id;
        name = [NSString stringWithUTF8String:results[i].modelName.c_str()];
        subject = [NSString stringWithUTF8String:results[i].subjectName.c_str()];
        notes = [NSString stringWithUTF8String:results[i].notes.c_str()];
        date = [NSString stringWithUTF8String:results[i].date.c_str()];
        stats = [NSString stringWithUTF8String:results[i].statistics.c_str()];
        
        value = results[i].value;

        currentResult = [[JKKResult alloc] initResultFromDatabaseWithID:resultID
                                                                   date:date
                                                                   name:name
                                                                subject:subject
                                                                  notes:notes
                                                                  value:value
                                                                stats:stats];
         
        
        [self.historyItems addObject:currentResult];
    }
    
    /* sort history items so latest is on top
    [self.historyItems sortedArrayUsingComparator:^NSComparisonResult(id a, id b){
        NSDate* dateA = [(JKKResult*)a date];
        NSDate* dateB = [(JKKResult*)b date];
        
        return [dateA compare:dateB];
    }];
    */
    
    [self.historyTable reloadData];
}

- (void) populateTestTable {
    // hessk: generate test (model) items from sqlite database
    
    [self.testItems removeAllObjects];
    
    DataStore p = [[JKKDatabaseManager sharedInstance] openDatabase];
    std::vector<ModelEntry> models = p.findAllModelEntries();
    p.close();
    
    JKKModel* currentModel;
    
    for (int i = 0; i < models.size(); i++) {
        currentModel = [[JKKModel alloc] initWithModel:homeFactory.deserializeFromDB(models[i].data, models[i].length) units:[NSString stringWithUTF8String:models[i].units.c_str()]];

        [self.testItems addObject:currentModel];
    }
    
    [self.testsTable reloadData];
}

#pragma mark UITableViewDelegate/UITableViewDataSource protocol methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    // hessk: this will be the number of items pulled from the Core Data objects
    
    if (tableView == self.testsTable) {
        //return the number of items in the test table
        return [self.testItems count];
    } else if (tableView == self.historyTable) {
        //return the number of items in the history table
        return [self.historyItems count];
    } else {
        //error: either throw an error or give a default value
    }
    
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier;
    
    
    if (tableView == self.testsTable) {
        cellIdentifier = @"TestsPrototypeCell";
    } else if (tableView == self.historyTable) {
        cellIdentifier = @"HistoryPrototypeCell";
    } else {
        //error
    }
    
    // hessk: assign specified prototype cell to this cell and get appropriate object from array at the same index
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    if (tableView == self.testsTable) {
        //JKKTest* testItem = [self.testItems objectAtIndex:indexPath.row];
        JKKModel* testItem = [self.testItems objectAtIndex:indexPath.row];
        cell.textLabel.text = [testItem getModelName];
        
        //RegressionModel::RegressionModel* testItem = (RegressionModel::RegressionModel *)CFBridgingRetain([self.testItems objectAtIndex:indexPath.row]);
        //cell.textLabel.text = [NSString stringWithCString: testItem->GetModelName().c_str()];
        
    } else if (tableView == self.historyTable) {
        NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
        [formatter setDateStyle:NSDateFormatterShortStyle];
        
        JKKResult* historyItem = [self.historyItems objectAtIndex:indexPath.row];
        
        // hessk: Get references to the prototype cells subviews by their tags (defined in IB)
        // But using literals like this is awkward. Consider alternatives.
        UILabel* title = (UILabel *)[cell.contentView viewWithTag:10];
        UILabel* detail = (UILabel *)[cell.contentView viewWithTag:11];
        
        title.text = historyItem.name;
        detail.text = [NSString stringWithFormat:@"Result: %.0f", historyItem.value];
    } else {
        //error
    }
    
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // hessk: row was selected - do something here?
    
    if (tableView == self.testsTable) {

    } else if (tableView == self.historyTable) {

    } else {

    }
    
}

/* hessk: this method overrides the UIViewController implementation, which does nothing.
    This is called whenever the view controller 'segues'. */
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showResults"]) {
        // hessk: pass on the selected history item to the history view controller instance
        NSIndexPath* selectedHistoryItemPath = [self.historyTable indexPathForSelectedRow];
        JKKResult* selectedResult = [self.historyItems objectAtIndex:selectedHistoryItemPath.row];
        
        [[segue destinationViewController] setResult:selectedResult];
        [[segue destinationViewController] setSourceView:self];
    } else if ([[segue identifier] isEqualToString:@"showTest"]) {
        // hessk: pass on the selected test to the test view controller instance
        NSIndexPath* selectedTestItemPath = [self.testsTable indexPathForSelectedRow];
        JKKModel* selectedTest = [self.testItems objectAtIndex:selectedTestItemPath.row];
        
        [[segue destinationViewController] setTest:selectedTest];
    } else if ([[segue identifier] isEqualToString:@"showNewTest"]) {
        // new test setup
        [[segue destinationViewController] setTest:nil];
    }
}

- (IBAction)unwindToHome:(UIStoryboardSegue *)segue {
    
    UIViewController* source = segue.sourceViewController;
    
    if ([source isKindOfClass:[JKKCalibrationListViewController class]]) {
        JKKTestViewController* testViewSource = (JKKTestViewController *)source;
        JKKModel* newTest = testViewSource.test;
        
        // if they came back from the test screen and there's a test - it must be new !!
        if (newTest != nil) {
            //[self.testItems addObject:newTest];
            DataStore p = [[JKKDatabaseManager sharedInstance] openDatabase];
            
            const void* blob;
            unsigned int len;
            
            homeFactory.serializeToDB(newTest.model, blob, len);
            
            ModelEntry entry(newTest.model->getModelName(), blob, len, [newTest.units UTF8String]);
            p.insertModelEntry(entry);
            p.close();
            
            [self populateTestTable];
        }
        
        [self.testsTable reloadData];
    } else if ([source isKindOfClass:[JKKSetupViewController class]] || [source isKindOfClass:[JKKResultsViewController class]]) {
        //results/models may have been changed, so repopulate the table
        [self populateHistoryTable];
        [self populateTestTable];
    }
}

@end
