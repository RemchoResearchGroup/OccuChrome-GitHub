//
//  JKKGraphViewController.m
//  App
//
//  Created by Kevin on 3/13/14.
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

#import "JKKGraphViewController.h"
#import "JKKCalibrationListViewController.h"

@interface JKKGraphViewController ()

@property NSMutableArray *pcaData;
@property NSMutableArray *pcaFitData;
@property float pcaMaxValue;

@end

@implementation JKKGraphViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.plotArray = [[NSMutableArray alloc] init];
    
    if (self.pca) {
        
        [self.discardButton setEnabled:NO];
        
        self.test.model->setRegressionGraphType(self.regressionType);
        
        self.pcaData = [[NSMutableArray alloc] init];
        self.pcaFitData = [[NSMutableArray alloc] init];
        
        [self initPCADataArray:self.pcaData];
        [self initPCAFitArray:self.pcaFitData];
    }
    
    [self initPlot];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if (sender == self.discardButton) {
        self.test.model->chuckCalibration(self.test.model->getGraphedCalibration());
        [[[segue destinationViewController] calibrationStatsTextView] setText:@""];
    }
}

// Fills PCA data array with x,y pairs from model PCA and initializes PCA max y value
- (void)initPCADataArray:(NSMutableArray *)newArray {
    float x;
    float y;
    float maxY = 0;
    CGPoint point;
    
    int i;
    
    for (i = 0; i < self.numCalibrationValues; i++) {
        self.test.model->getCalibrationPointPostPCA(i, x, y);
        
        if (y > maxY) {
            maxY = y;
        }
        
        point = CGPointMake(x, y);
        [newArray addObject:[NSValue valueWithCGPoint:point]];
    }
    
    self.pcaMaxValue = maxY;
}

- (void)initPCAFitArray:(NSMutableArray *)newArray {
    float x;
    float y;
    
    float minX;
    float maxX;
    
    CGPoint point;

    float step;
    
    self.test.model->getPCASpaceRange(minX, maxX);
    step = (maxX - minX) / 100.0;
    
    minX = floorf(minX);
    maxX = ceilf(maxX);
    
    float i;
    
    for (i = minX; i <= maxX; i += step) {
        x = i;
        y = self.test.model->getFinalRegressionLine(i);
        point = CGPointMake(x, y);
        [newArray addObject:[NSValue valueWithCGPoint:point]];
    }
}

#pragma mark - Chart behavior
-(void)initPlot {
    [self configureHost];
    [self configureGraph];
    [self configurePlots];
    [self configureAxes];
}

-(void)configureHost {
    self.hostView.allowPinchScaling = YES;
}

-(void)configureGraph {
    // 1 - Create the graph
    CPTGraph *graph = [[CPTXYGraph alloc] initWithFrame:self.hostView.bounds];
    [graph applyTheme:[CPTTheme themeNamed:kCPTPlainWhiteTheme]];
    graph.plotAreaFrame.borderLineStyle = nil;
    self.hostView.hostedGraph = graph;
    
    // 2 - Set graph title
    NSString *title = @"Calibration Plot";
    graph.title = title;
    
    // 3 - Create and set text style
    CPTMutableTextStyle *titleStyle = [CPTMutableTextStyle textStyle];
    titleStyle.color = [CPTColor whiteColor];
    titleStyle.fontName = @"Helvetica-Bold";
    titleStyle.fontSize = 16.0f;
    graph.titleTextStyle = titleStyle;
    graph.titlePlotAreaFrameAnchor = CPTRectAnchorTop;
    graph.titleDisplacement = CGPointMake(0.0f, 10.0f);
    
    // 4 - Set padding for plot area
    [graph.plotAreaFrame setPaddingLeft:30.0f];
    [graph.plotAreaFrame setPaddingBottom:30.0f];
    
    // 5 - Enable user interactions for plot space
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *) graph.defaultPlotSpace;
    plotSpace.allowsUserInteraction = YES;
}

-(void)configurePlots {
    // 1 - Get graph and plot space
    CPTGraph *graph = self.hostView.hostedGraph;
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *) graph.defaultPlotSpace;
    
    // 2 - Create plots
    
    if (self.pca) {
        CPTScatterPlot *pcaDataPlot = [[CPTScatterPlot alloc] init];
        pcaDataPlot.dataSource = self;
        pcaDataPlot.identifier = @"PCA_DATA";
        CPTColor *pcaDataColor = [CPTColor clearColor];
        [graph addPlot:pcaDataPlot toPlotSpace:plotSpace];
        
        CPTMutableLineStyle *pcaDataLineStyle = [pcaDataPlot.dataLineStyle mutableCopy];
        
        pcaDataLineStyle.lineWidth = 0;
        pcaDataLineStyle.lineColor = pcaDataColor;
        pcaDataPlot.dataLineStyle = pcaDataLineStyle;
        
        CPTMutableLineStyle *pcaDataSymbolLineStyle = [CPTMutableLineStyle lineStyle];
        pcaDataSymbolLineStyle.lineColor = pcaDataColor;
        CPTPlotSymbol *pcaDataSymbol = [CPTPlotSymbol ellipsePlotSymbol];
        pcaDataSymbol.fill = [CPTFill fillWithColor:[CPTColor blackColor]];
        pcaDataSymbol.lineStyle = pcaDataSymbolLineStyle;
        pcaDataSymbol.size = CGSizeMake(6.0f, 6.0f);
        pcaDataPlot.plotSymbol = pcaDataSymbol;
        
        CPTScatterPlot *pcaFitPlot = [[CPTScatterPlot alloc] init];
        pcaFitPlot.dataSource = self;
        pcaFitPlot.identifier = @"PCA_FIT";
        CPTColor *pcaFitColor = [CPTColor blueColor];
        [graph addPlot:pcaFitPlot toPlotSpace:plotSpace];
        
        CPTMutableLineStyle *pcaFitLineStyle = [pcaFitPlot.dataLineStyle mutableCopy];
        
        pcaFitLineStyle.lineWidth = 2.5;
        pcaFitLineStyle.lineColor = pcaFitColor;
        pcaFitPlot.dataLineStyle = pcaFitLineStyle;
        
        CPTMutableLineStyle *pcaFitSymbolLineStyle = [CPTMutableLineStyle lineStyle];
        pcaFitSymbolLineStyle.lineColor = [CPTColor clearColor];
        CPTPlotSymbol *pcaFitSymbol = [CPTPlotSymbol ellipsePlotSymbol];
        pcaFitSymbol.fill = [CPTFill fillWithColor:[CPTColor clearColor]];
        pcaFitSymbol.lineStyle = pcaFitSymbolLineStyle;
        pcaFitSymbol.size = CGSizeMake(6.0f, 6.0f);
        pcaFitPlot.plotSymbol = pcaFitSymbol;
        
        [self.plotArray addObject:pcaDataPlot];
        [self.plotArray addObject:pcaFitPlot];
        
    } else {
        CPTScatterPlot *redPlot = [[CPTScatterPlot alloc] init];
        redPlot.dataSource = self;
        redPlot.identifier = @"RED";
        CPTColor *redColor = [CPTColor redColor];
        [graph addPlot:redPlot toPlotSpace:plotSpace];
        
        CPTMutableLineStyle *redLineStyle = [redPlot.dataLineStyle mutableCopy];
        redLineStyle.lineWidth = 2.5;
        redLineStyle.lineColor = redColor;
        redPlot.dataLineStyle = redLineStyle;
        CPTMutableLineStyle *redSymbolLineStyle = [CPTMutableLineStyle lineStyle];
        redSymbolLineStyle.lineColor = redColor;
        CPTPlotSymbol *redSymbol = [CPTPlotSymbol ellipsePlotSymbol];
        redSymbol.fill = [CPTFill fillWithColor:redColor];
        redSymbol.lineStyle = redSymbolLineStyle;
        redSymbol.size = CGSizeMake(6.0f, 6.0f);
        redPlot.plotSymbol = redSymbol;
        
        CPTScatterPlot *greenPlot = [[CPTScatterPlot alloc] init];
        greenPlot.dataSource = self;
        greenPlot.identifier = @"GREEN";
        CPTColor *greenColor = [CPTColor greenColor];
        [graph addPlot:greenPlot toPlotSpace:plotSpace];
        
        CPTMutableLineStyle *greenLineStyle = [greenPlot.dataLineStyle mutableCopy];
        greenLineStyle.lineWidth = 1.0;
        greenLineStyle.lineColor = greenColor;
        greenPlot.dataLineStyle = greenLineStyle;
        CPTMutableLineStyle *greenSymbolLineStyle = [CPTMutableLineStyle lineStyle];
        greenSymbolLineStyle.lineColor = greenColor;
        CPTPlotSymbol *greenSymbol = [CPTPlotSymbol ellipsePlotSymbol];
        greenSymbol.fill = [CPTFill fillWithColor:greenColor];
        greenSymbol.lineStyle = greenSymbolLineStyle;
        greenSymbol.size = CGSizeMake(6.0f, 6.0f);
        greenPlot.plotSymbol = greenSymbol;
        
        CPTScatterPlot *bluePlot = [[CPTScatterPlot alloc] init];
        bluePlot.dataSource = self;
        bluePlot.identifier = @"BLUE";
        CPTColor *blueColor = [CPTColor blueColor];
        [graph addPlot:bluePlot toPlotSpace:plotSpace];
        
        CPTMutableLineStyle *blueLineStyle = [bluePlot.dataLineStyle mutableCopy];
        blueLineStyle.lineWidth = 2.0;
        blueLineStyle.lineColor = blueColor;
        bluePlot.dataLineStyle = blueLineStyle;
        CPTMutableLineStyle *blueSymbolLineStyle = [CPTMutableLineStyle lineStyle];
        blueSymbolLineStyle.lineColor = blueColor;
        CPTPlotSymbol *blueSymbol = [CPTPlotSymbol ellipsePlotSymbol];
        blueSymbol.fill = [CPTFill fillWithColor:blueColor];
        blueSymbol.lineStyle = blueSymbolLineStyle;
        blueSymbol.size = CGSizeMake(6.0f, 6.0f);
        bluePlot.plotSymbol = blueSymbol;
        
        for (int i = 0; i < self.test.model->queryNumComponents(); i++) {
            CPTScatterPlot *newPlot = [self makePlotWithID:[NSNumber numberWithInt:i]];
            [self.plotArray addObject:newPlot];
            [graph addPlot:newPlot];
        }
        
        [self.plotArray addObject:redPlot];
        [self.plotArray addObject:greenPlot];
        [self.plotArray addObject:bluePlot];
    }
    
    // 3 - Set up plot space
    [plotSpace scaleToFitPlots:self.plotArray];
    CPTMutablePlotRange *xRange = [plotSpace.xRange mutableCopy];
    [xRange expandRangeByFactor:CPTDecimalFromCGFloat(1.1f)];
    plotSpace.xRange = xRange;
    CPTMutablePlotRange *yRange = [plotSpace.yRange mutableCopy];
    [yRange expandRangeByFactor:CPTDecimalFromCGFloat(1.2f)];
    plotSpace.yRange = yRange;
}

-(void)configureAxes {
    CGFloat runTime = self.test.model->getModelRunTime();
    
    NSString *xAxisTitle;
    NSString *yAxisTitle;
    
    float xMin;
    float xMax;
    
    CGFloat yMax;
    
    NSInteger majorIncrement;
    NSInteger minorIncrement;
    
    if (self.pca) {
        xAxisTitle = @"";
        yAxisTitle = [NSString stringWithFormat:@"Concentration (%@)", self.test.units];
        
        self.test.model->getPCASpaceRange(xMin, xMax);
        xMin= floorf(xMin);
        xMax = ceilf(xMax);
        
        yMax = self.pcaMaxValue;
        
        majorIncrement = 5;
        minorIncrement = 2.5;
    } else {
        xAxisTitle = @"Time (s)";
        yAxisTitle = @"Value";
        
        xMin = 0;
        xMax = runTime;
        
        yMax = 255.0;
        
        majorIncrement = 50;
        minorIncrement = 25;
    }
    
    // 1 - Create styles
    CPTMutableTextStyle *axisTitleStyle = [CPTMutableTextStyle textStyle];
    axisTitleStyle.color = [CPTColor blackColor];
    axisTitleStyle.fontName = @"Helvetica-Bold";
    axisTitleStyle.fontSize = 12.0f;
    CPTMutableLineStyle *axisLineStyle = [CPTMutableLineStyle lineStyle];
    axisLineStyle.lineWidth = 2.0f;
    axisLineStyle.lineColor = [CPTColor blackColor];
    CPTMutableTextStyle *axisTextStyle = [[CPTMutableTextStyle alloc] init];
    axisTextStyle.color = [CPTColor blackColor];
    axisTextStyle.fontName = @"Helvetica-Bold";
    axisTextStyle.fontSize = 11.0f;
    CPTMutableLineStyle *tickLineStyle = [CPTMutableLineStyle lineStyle];
    tickLineStyle.lineColor = [CPTColor blackColor];
    tickLineStyle.lineWidth = 2.0f;
    CPTMutableLineStyle *gridLineStyle = [CPTMutableLineStyle lineStyle];
    tickLineStyle.lineColor = [CPTColor grayColor];
    tickLineStyle.lineWidth = 1.0f;
    
    // 2 - Get axis set
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *) self.hostView.hostedGraph.axisSet;
    
    // 3 - Configure x-axis
    CPTAxis *x = axisSet.xAxis;
    x.title = xAxisTitle;
    x.titleTextStyle = axisTitleStyle;
    x.titleOffset = 15.0f;
    x.axisLineStyle = axisLineStyle;
    x.labelingPolicy = CPTAxisLabelingPolicyNone;
    x.labelTextStyle = axisTextStyle;
    x.majorTickLineStyle = axisLineStyle;
    x.majorTickLength = 4.0f;
    x.tickDirection = CPTSignNegative;
    
    
    NSMutableSet *xLabels = [NSMutableSet setWithCapacity:xMax];
    NSMutableSet *xLocations = [NSMutableSet setWithCapacity:xMax];
    
    int i;
    for (i = xMin; i <= xMax; i++) {
        CPTAxisLabel *label = [[CPTAxisLabel alloc] initWithText:[NSString stringWithFormat:@"%d", i] textStyle:x.labelTextStyle];
        CGFloat location = i;
        
        label.tickLocation = CPTDecimalFromCGFloat(location);
        label.offset = x.majorTickLength;
        
        if (label) {
            [xLabels addObject:label];
            [xLocations addObject:[NSNumber numberWithFloat:location]];
        }
    }
    
    x.axisLabels = xLabels;
    x.majorTickLocations = xLocations;
    
    // 4 - Configure y-axis
    CPTAxis *y = axisSet.yAxis;
    y.title = yAxisTitle;
    y.titleTextStyle = axisTitleStyle;
    y.titleOffset = -40.0f;
    
    y.axisLineStyle = axisLineStyle;
    y.majorGridLineStyle = gridLineStyle;
    y.labelingPolicy = CPTAxisLabelingPolicyNone;
    y.labelTextStyle = axisTextStyle;
    y.labelOffset = 16.0f;
    
    y.majorTickLineStyle = axisLineStyle;
    y.majorTickLength = 4.0f;
    y.minorTickLength = 2.0f;
    
    y.tickDirection = CPTSignPositive;
    
    
    
    NSMutableSet *yLabels = [NSMutableSet set];
    NSMutableSet *yMajorLocations = [NSMutableSet set];
    NSMutableSet *yMinorLocations = [NSMutableSet set];
    
    for (NSInteger j = minorIncrement; j <= yMax; j += minorIncrement) {
        NSUInteger mod = j % majorIncrement;
        if (mod == 0) {
            CPTAxisLabel *label = [[CPTAxisLabel alloc] initWithText:[NSString stringWithFormat:@"%i", j] textStyle:y.labelTextStyle];
            NSDecimal location = CPTDecimalFromInteger(j);
            label.tickLocation = location;
            label.offset = -y.majorTickLength - y.labelOffset;
            if (label) {
                [yLabels addObject:label];
            }
            [yMajorLocations addObject:[NSDecimalNumber decimalNumberWithDecimal:location]];
        } else {
            [yMinorLocations addObject:[NSDecimalNumber decimalNumberWithDecimal:CPTDecimalFromInteger(j)]];
        }
    }
    y.axisLabels = yLabels;    
    y.majorTickLocations = yMajorLocations;
    y.minorTickLocations = yMinorLocations;
}

- (CPTScatterPlot *)makePlotWithID:(id)identifer {
    
    CPTScatterPlot *plot = [[CPTScatterPlot alloc] init];
    //CPTScatterPlot *redPlot = [[CPTScatterPlot alloc] init];
    plot.dataSource = self;
    plot.identifier = identifer;
    //hessk: TODO: black for now
    CPTColor *plotColor = [CPTColor blackColor];
    //[graph addPlot:redPlot toPlotSpace:plotSpace];
    
    CPTMutableLineStyle *plotLineStyle = [plot.dataLineStyle mutableCopy];
    plotLineStyle.lineWidth = 2.5;
    plotLineStyle.lineColor = plotColor;
    plot.dataLineStyle = plotLineStyle;
    CPTMutableLineStyle *plotSymbolLineStyle = [CPTMutableLineStyle lineStyle];
    plotSymbolLineStyle.lineColor = plotColor;
    CPTPlotSymbol *plotSymbol = [CPTPlotSymbol ellipsePlotSymbol];
    plotSymbol.fill = [CPTFill fillWithColor:plotColor];
    plotSymbol.lineStyle = plotSymbolLineStyle;
    plotSymbol.size = CGSizeMake(6.0f, 6.0f);
    plot.plotSymbol = plotSymbol;
    
    return plot;
}

#pragma mark - CPTPlotDataSource methods
-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot {
    // hessk:return number of points for this plot (red, green, or blue)
    if ([plot.identifier isEqual:@"PCA_DATA"]) {
        return [self.pcaData count];
    } else if ([plot.identifier isEqual:@"PCA_FIT"]) {
        return [self.pcaFitData count];
    } else {
        return self.test.model->getModelRunTime();
    }
}

/*
-(NSArray *)numbersForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndexRange:(NSRange)indexRange {
    switch (fieldEnum) {
        case CPTScatterPlotFieldX:
            if ([plot.identifier isEqual:@"PCA_DATA"]) {
                // array of x values for pca data in indexRange
                
                float stuff = indexRange;
                
            } else if ([plot.identifier isEqual:@"PCA_FIT"]) {
                // array of x values for pca fit in indexRange
            } else {
                // array of x values for rgb/calibration fit plots
            }
            break;
        case CPTScatterPlotFieldY:
            if ([plot.identifier isEqual:@"PCA_DATA"]) {
                // array of y values for pca data in indexRange
            } else if ([plot.identifier isEqual:@"PCA_FIT"]) {
                // array of y values for pca fit in indexRange
            } else if ([plot.identifier isEqual:@"RED"]) {
                // array of y values for red
            } else if ([plot.identifier isEqual:@"GREEN"]) {
                // array of y values for green
            } else if ([plot.identifier isEqual:@"BLUE"]) {
                // array of y values for blue
            } else {
                // array of y values for others
            }
            break;
        default:
            break;
    }
}
 */

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index {
    // hessk: valueCount should be number of x values
    NSInteger valueCount;
    CGPoint dataPoint, fitPoint;
    
    if (self.pca) {
        if (index < [self.pcaData count])
            dataPoint = [[self.pcaData objectAtIndex:index] CGPointValue];
        
        if (index < [self.pcaFitData count])
            fitPoint = [[self.pcaFitData objectAtIndex:index] CGPointValue];
    }
    
    switch (fieldEnum) {
        case CPTScatterPlotFieldX:
            if ([plot.identifier isEqual:@"PCA_DATA"]) {
                valueCount = [self.pcaData count];
                if (index < valueCount) {
                    return [NSNumber numberWithFloat:dataPoint.x];
                }
            } else if ([plot.identifier isEqual:@"PCA_FIT"]) {
                valueCount = [self.pcaFitData count];
                if (index < valueCount) {
                    return [NSNumber numberWithFloat:fitPoint.x];
                }
            } else {
                valueCount = self.test.model->getModelRunTime();
                if (index < valueCount) {
                    return [NSNumber numberWithUnsignedInteger:index];
                }
            }
            break;
            
        case CPTScatterPlotFieldY:
            if ([plot.identifier isEqual:@"RED"] == YES) {
                //hessk: return red plot y value for x index
                return [NSNumber numberWithFloat:self.test.model->getRed(index)];
            } else if ([plot.identifier isEqual:@"GREEN"] == YES) {
                //hessk: return green plot y value for x index
                return [NSNumber numberWithFloat:self.test.model->getGreen(index)];
            } else if ([plot.identifier isEqual:@"BLUE"] == YES) {
                //hessk: return blue plot y value for x index
                return [NSNumber numberWithFloat:self.test.model->getBlue(index)];
            } else if ([plot.identifier isEqual:@"PCA_DATA"]) {
                //hessk: return y value pca scatter plot point
                return [NSNumber numberWithFloat:dataPoint.y];
            } else if ([plot.identifier isEqual:@"PCA_FIT"]) {
                //hessk: return y value for pca best fit line
                return [NSNumber numberWithFloat:fitPoint.y];
            } else {
                float val = self.test.model->getRegressionPoint([(NSNumber *)plot.identifier integerValue], index);
                
                if (val != 0) {
                    return [NSNumber numberWithFloat:val];
                } else {
                    return nil;
                }
            }
            break;
    }
    
    return [NSDecimalNumber zero];
}

@end
