//
//  TIOManager.m
//  TerminalIO
//
//  Created by Telit
//  Copyright (c) Telit Wireless Solutions GmbH, Germany
//

#import "TIO.h"
#import "TIOManager_internal.h"
#import "TIOPeripheral_internal.h"
#import "TIOAdvertisement.h"
#import "STTrace.h"


@interface TIOManager () <CBCentralManagerDelegate>

@property (strong, nonatomic) CBCentralManager *cbCentralManager;
@property (strong, nonatomic) NSMutableArray *tioPeripherals;

@end



@implementation TIOManager
NSString *const KNOWN_PERIPHERAL_IDS_FILE_NAME = @"TIOKnownPeripheralIdentifiers";

#pragma  mark - Initialization

- (TIOManager *) init
{
    NSString *appBundleId = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    NSString *restoreIdentifierKey = [NSString stringWithFormat:@"%@/%@", @"TIOManager", appBundleId];
    NSDictionary * options = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithBool:YES], CBCentralManagerOptionShowPowerAlertKey,
                              restoreIdentifierKey, CBCentralManagerOptionRestoreIdentifierKey,
                              nil];
    self = [super init];
    if (self)
    {
        // Allocate the IOS Core Bluetooth Central Manager instance opting for restoration.
        // With CBCentralManagerOptionShowPowerAlertKey iOS will automatically inform the user if they have Bluetooth turned off.
        self.cbCentralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:options];
        // Allocate an array for holding the discovered peripheral instances.
        self.tioPeripherals = [[NSMutableArray alloc] init];
    }
    return self;
}

- (TIOManager *) initWithQueue: (dispatch_queue_t) queue
{
    NSString *appBundleId = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    NSString *restoreIdentifierKey = [NSString stringWithFormat:@"%@-%@", @"TIOManager", appBundleId];
    NSDictionary * options = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithBool:YES], CBCentralManagerOptionShowPowerAlertKey,
                              restoreIdentifierKey, CBCentralManagerOptionRestoreIdentifierKey,
                              nil];
    self = [super init];
    if (self)
    {
        // Allocate the IOS Core Bluetooth Central Manager instance opting for restoration.
        // With CBCentralManagerOptionShowPowerAlertKey iOS will automatically inform the user if they have Bluetooth turned off.
        self.cbCentralManager = [[CBCentralManager alloc] initWithDelegate:self queue:queue options:options];
        // Allocate an array for holding the discovered peripheral instances.
        self.tioPeripherals = [[NSMutableArray alloc] init];
 }
    return self;
}


#pragma  mark - Properties

- (NSArray *)peripherals
{
    [[STTrace sharedInstance] line:@"peripherals count %ld", self.tioPeripherals.count];
    return [self.tioPeripherals copy];
}


#pragma mark - Public methods

+ (TIOManager *)sharedInstance
{
    return [TIOManager sharedInstanceWithQueue:nil];
#if 0
    // Lazyly instantiated TIOManager singleton.
    static __strong TIOManager *_sharedInstance = nil;
    if (!_sharedInstance)
    {
        _sharedInstance = [[TIOManager alloc] init];
    }
    return _sharedInstance;
#endif
}

+ (TIOManager *)sharedInstanceWithQueue:(dispatch_queue_t)queue
{
    // Lazyly instantiated TIOManager singleton.
    static __strong TIOManager *_sharedInstance = nil;
    if (!_sharedInstance)
    {
        _sharedInstance = [[TIOManager alloc] initWithQueue:queue];
    }
    return _sharedInstance;
}

- (void)startScan
{
    //STTraceMethod(self, @"startScan");

    // Scan for devices exposing the TerminalIO Service; do not allow duplicates (default options).
    [self.cbCentralManager 	scanForPeripheralsWithServices: @[[TIO SERVICE_UUID]] options:nil];
}


- (void)startUpdateScan
{
    //STTraceMethod(self, @"startUpdateScan");

    // Scan for devices exposing the TerminalIO Service; do allow duplicates.
    // This option is not recommended, leads to increased power consumption and may be disabled by the OS when in background mode.
    // It is used here in order to capture dynamically changing advertisement information during this scan procedure.
    [self.cbCentralManager scanForPeripheralsWithServices: @[[TIO SERVICE_UUID]] options:@{CBCentralManagerScanOptionAllowDuplicatesKey: @YES}];
}


- (void)stopScan
{
    //STTraceMethod(self, @"stopScan");

    // Stop scan.
    [self.cbCentralManager stopScan];
}


- (void)loadPeripherals
{
    [[STTrace sharedInstance] line:@"loadPeripherals1 oldlist: %ld", self.tioPeripherals.count];

    NSString *path = [TIO pathWithFileName:KNOWN_PERIPHERAL_IDS_FILE_NAME];
    NSMutableArray* idList = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    if (idList == nil)
    {
        [[STTrace sharedInstance] line:@"Failed to deserialize identifier list"];
        return;
    }

    NSArray *idArray = [idList copy];
    [[STTrace sharedInstance] line:@"loadPeripherals2 %ld", (long)idList.count];
    NSArray	 *list = [self.cbCentralManager retrievePeripheralsWithIdentifiers:idArray];
    for (CBPeripheral *peripheral in list)
    {
        // check for existing instance
        [[STTrace sharedInstance] line:(@"loadPeripherals3: ------- %@", peripheral.name)];
        TIOPeripheral *knownPeripheral = [self findTIOPeripheralByIdentifier:peripheral.identifier];
        if (knownPeripheral != nil) {
            knownPeripheral.shallBeSaved = true;
            continue;
        }

        //STTraceLine(@"retrieved peripheral %@", peripheral);
        // Create a new TIOPeripheral instance from discovered data.
        TIOPeripheral *tioPeripheral = [TIOPeripheral peripheralWithCBPeripheral:peripheral];
        tioPeripheral.shallBeSaved = true;
        // Add new instance to collection.
        [self.tioPeripherals addObject:tioPeripheral];
        // Notify delegate.
        [self raiseDidRetrievePeripheral:tioPeripheral];
    }
    [[STTrace sharedInstance] line:@"loadPeripherals peripherals count4 %ld", self.tioPeripherals.count];
}

- (void)savePeripherals
{
    [[STTrace sharedInstance] line:@"savePeripherals1"];

    NSMutableArray *idList = [[NSMutableArray alloc] init];
    for (TIOPeripheral *peripheral in self.peripherals)
    {
        if (peripheral.shallBeSaved)
        {
            [[STTrace sharedInstance] line:@"savePeripherals2------: %@", peripheral.name];
            [idList addObject:peripheral.cbPeripheral.identifier];
        }
    }


    NSString *path = [TIO pathWithFileName:KNOWN_PERIPHERAL_IDS_FILE_NAME];
    if (![NSKeyedArchiver archiveRootObject:idList toFile:path])
    {
        [[STTrace sharedInstance] line:@"failed to serialize identifier list"];
    }
}


- (void)removePeripheral:(TIOPeripheral *)peripheral
{
    [[STTrace sharedInstance] line:@"removePeripheral %@", peripheral];

    // remove instance from collection with filter
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier != %@", peripheral.identifier];
    NSArray *filteredArray = [self.tioPeripherals filteredArrayUsingPredicate:predicate];
    [self.tioPeripherals removeAllObjects];
    [self.tioPeripherals addObjectsFromArray:filteredArray];
    // save updated peripheral collection
    [self savePeripherals];
    // disconnect
    [peripheral cancelConnection];

}


- (void)removeAllPeripherals
{
    //STTraceMethod(self, @"removeAllPeripherals");

    [[STTrace sharedInstance] line:@"removeAllPeripherals"];
    for (TIOPeripheral *peripheral in self.tioPeripherals)
    {
        // disconnect
        [peripheral cancelConnection];
    }

    [self.tioPeripherals removeAllObjects];
    // save cleared peripheral collection
    [self savePeripherals];
}


#pragma mark - Internal methods

- (TIOPeripheral *)findTIOPeripheralByIdentifier:(NSUUID *)identifier
{
//    [[STTrace sharedInstance] line:@"findTIOPeripheralByIdentifier %d", identifier];

    // Iterate through known peripherals.
    for (TIOPeripheral *peripheral in self.tioPeripherals)
    {
        if ([peripheral.identifier isEqual:identifier])
        {
            // Found matching TIOPeripheral instance.
            return peripheral;
        }
    }

    return nil;
}


#pragma mark - CBCentralManagerDelegate implementation

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    [self loadPeripherals];
    [[STTrace sharedInstance] line:@"centralManagerDidUpdateState %d", central.state];

    if (central.state == CBCentralManagerStatePoweredOn)
    {
        for (TIOPeripheral *peripheral in self.tioPeripherals)
        {
            if (peripheral.shallBeSaved)
            {
                [self.cbCentralManager cancelPeripheralConnection:peripheral.cbPeripheral];
            }
        }
        [self raiseBluetoothAvailable];
    }
    else
    {

//        NSArray<CBPeripheral *> *list = [self.cbCentralManager retrieveConnectedPeripheralsWithServices:@[[TIO SERVICE_UUID]]];
        for (TIOPeripheral *peripheral in self.tioPeripherals)
        {
            if (peripheral.shallBeSaved)
            {
                [peripheral cancelConnection];
            }
        }
        [self raiseBluetoothUnavailable];
    }
}


- (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary *)dict
{
    NSArray *peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey];
    for  (CBPeripheral *peripheral in peripherals) {
        [[STTrace sharedInstance] line:@"centralManagerWillRestoreState %@", peripheral.name];

        TIOPeripheral *knownPeripheral = [self findTIOPeripheralByIdentifier:peripheral.identifier];
        if (knownPeripheral != nil) {
            knownPeripheral.shallBeSaved = true;
            continue;
        }

        //STTraceLine(@"retrieved peripheral %@", peripheral);
        // Create a new TIOPeripheral instance from discovered data.
        TIOPeripheral *tioPeripheral = [TIOPeripheral peripheralWithCBPeripheral:peripheral];
        tioPeripheral.shallBeSaved = true;
        // Add new instance to collection.
        [self.tioPeripherals addObject:tioPeripheral];
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    [[STTrace sharedInstance] line:@"centralManagerDidDiscoverPeripheral %@  rssi:%@", peripheral, RSSI];
    [[STTrace sharedInstance] line:@"centralManagerDidDiscoverPeripheral advertisementData %@", advertisementData];
    
    if ([advertisementData objectForKey:CBAdvertisementDataLocalNameKey]) {
        NSString *deviceName = [advertisementData objectForKey:CBAdvertisementDataLocalNameKey];
        NSLog(@"Discovered peripheral: %@ with advertisement name: %@", peripheral.name, deviceName);
    } else {
        NSLog(@"Discovered peripheral: %@ (No advertisement name found)", peripheral.name);
        return;
    }
    
    // Instantiate delegate a TIOAdvertisement from discovered advertisement data.
    TIOAdvertisement *advertisement = [TIOAdvertisement advertisementWithData:advertisementData];
    if (advertisement == nil)
    {
        //STTraceError(@"invalid advertisement");
        return;
    }

    // Check for already known TIOPeripheral instance.
    
    TIOPeripheral *knownPeripheral = [self findTIOPeripheralByIdentifier:peripheral.identifier];
    if (knownPeripheral != nil) {
        if (![knownPeripheral.advertisement isEqualToAdvertisement:advertisement]) {
            [knownPeripheral setAdvertisement:advertisement];
            [self raiseDidUpdatePeripheral:knownPeripheral];
        }
        return;
    }

    // Create a new TIOPeripheral instance from discovered data.
    TIOPeripheral *newPeripheral = [TIOPeripheral peripheralWithCBPeripheral:peripheral andAdvertisement:advertisement];
    // Notify delegate.
    [self raiseDidDiscoverPeripheral:newPeripheral];

   // Add new instance to collection.
   [self.tioPeripherals addObject:newPeripheral];
   // save updated peripheral collection
   [self savePeripherals];
}


- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    [[STTrace sharedInstance] line:@"centralManagerDidConnectPeripheral %@", peripheral];

    // Find the corresponding TIOPeripheral instance...
    TIOPeripheral *tioPeripheral = [self findTIOPeripheralByIdentifier:peripheral.identifier];
    if (tioPeripheral)
    {
        // ... and let the TIOPeripheral instance handle the event.
        [tioPeripheral didConnect];
    }else{
        [self.cbCentralManager cancelPeripheralConnection: peripheral];
    }
}


- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    [[STTrace sharedInstance] line:@"centralManagerDidFailToConnectPeripheral %@, %@", peripheral, error];
    // Find the corresponding TIOPeripheral instance...
    TIOPeripheral *tioPeripheral = [self findTIOPeripheralByIdentifier:peripheral.identifier];
    if (tioPeripheral)
    {
        // ... and let the TIOPeripheral instance handle the event.
        [tioPeripheral didFailToConnectWithError:error];
    }
}


- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    [[STTrace sharedInstance] line:@"centralManagerDidDisconnectPeripheral %@, %@", peripheral, error];
    // Find the corresponding TIOPeripheral instance...
    TIOPeripheral *tioPeripheral = [self findTIOPeripheralByIdentifier:peripheral.identifier];
    if (tioPeripheral)
    {
        if(error == nil){
            NSError* err = [NSError errorWithDomain:@"didDisconnectPeripheral" code:@"didDisconnectPeripheral" userInfo:nil];
            [tioPeripheral didDisconnectWithError:err];
        } else {
            [tioPeripheral didDisconnectWithError:error];
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral timestamp:(CFAbsoluteTime)timestamp isReconnecting:(BOOL)isReconnecting error:(NSError *)error
{
    [[STTrace sharedInstance] line:@"didDisconnectPeripheral %@, %@", peripheral, error];
}

#pragma mark - Delegate events

- (void)raiseBluetoothAvailable
{
    if ([self.delegate respondsToSelector:@selector(tioManagerBluetoothAvailable:)])
        [self.delegate tioManagerBluetoothAvailable:self];
}


- (void)raiseBluetoothUnavailable
{
    if ([self.delegate respondsToSelector:@selector(tioManagerBluetoothUnavailable:)])
        [self.delegate tioManagerBluetoothUnavailable:self];
}


- (void)raiseDidDiscoverPeripheral:(TIOPeripheral *)peripheral
{
    if ([self.delegate respondsToSelector:@selector(tioManager:didDiscoverPeripheral:)])
        [self.delegate tioManager:self didDiscoverPeripheral:peripheral];
}


- (void)raiseDidRetrievePeripheral:(TIOPeripheral *)peripheral
{
    [[STTrace sharedInstance] line:@"raiseDidRetrievePeripheral %@", peripheral.name];
    if ([self.delegate respondsToSelector:@selector(tioManager:didRetrievePeripheral:)])
        [self.delegate tioManager:self didRetrievePeripheral:peripheral];
}


- (void)raiseDidUpdatePeripheral:(TIOPeripheral *)peripheral
{
    if ([self.delegate respondsToSelector:@selector(tioManager:didUpdatePeripheral:)])
        [self.delegate tioManager:self didUpdatePeripheral:peripheral];
}



#pragma mark - Internal interface towards TIOPeripheral

- (void)connectPeripheral:(TIOPeripheral *)peripheral
{
    //STTraceMethod(self, @"connectPeripheral %@", peripheral);

    [self.cbCentralManager connectPeripheral:peripheral.cbPeripheral options:nil];
}


- (void)cancelPeripheralConnection:(TIOPeripheral *)peripheral
{
    //STTraceMethod(self, @"cancelPeripheralConnection %@", peripheral);

    [self.cbCentralManager cancelPeripheralConnection:peripheral.cbPeripheral];
}

#pragma mark - Other

- (CBCentralManager *)getCentralManager
{
    return self.cbCentralManager;
}
@end

