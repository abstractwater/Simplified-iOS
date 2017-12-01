#import "NSDate+NYPLDateAdditions.h"
#import "NYPLXML.h"

#import "NYPLOPDSLink.h"

@interface NYPLOPDSLink ()

@property (nonatomic) NSDictionary *attributes;
@property (nonatomic) NSURL *href;
@property (nonatomic) NSString *rel;
@property (nonatomic) NSString *type;
@property (nonatomic) NSString *hreflang;
@property (nonatomic) NSString *title;
@property (nonatomic) NSString *length;
@property (nonatomic) NSString *availabilityStatus;
@property (nonatomic) NSInteger availableCopies;
@property (nonatomic) NSInteger totalCopies;
@property (nonatomic) NSInteger holdsPosition;
@property (nonatomic) NSDate *availableSince;
@property (nonatomic) NSDate *availableUntil;
@property (nonatomic) NSMutableArray *mutableAcquisitionFormats;

@end

@implementation NYPLOPDSLink

- (instancetype)initWithXML:(NYPLXML *const)linkXML
{
  self = [super init];
  if(!self) return nil;
  
  {
    NSString *const hrefString = linkXML.attributes[@"href"];
    if(!hrefString) {
      NYPLLOG(@"Missing required 'href' attribute.");
      return nil;
    }
    
    if(!((self.href = [NSURL URLWithString:hrefString]))) {
      // Atom requires support for RFC 3986, but CFURL and NSURL only support RFC 2396. As such, a
      // valid URI may be rejected in extremely rare cases.
      NYPLLOG(@"'href' attribute does not contain an RFC 2396 URI.");
      return nil;
    }
  }
  
  self.attributes = linkXML.attributes;
  self.rel = linkXML.attributes[@"rel"];
  self.type = linkXML.attributes[@"type"];
  self.hreflang = linkXML.attributes[@"hreflang"];
  self.title = linkXML.attributes[@"title"];
  self.length = linkXML.attributes[@"length"];
  self.mutableAcquisitionFormats = [NSMutableArray array];
  
  NYPLXML *availabilityXML = [linkXML firstChildWithName:@"availability"];
  if (availabilityXML) {
    NSDictionary *attributes = availabilityXML.attributes;
    self.availabilityStatus = attributes[@"status"];
    self.availableSince = [NSDate dateWithRFC3339String:attributes[@"since"]];
    self.availableUntil = [NSDate dateWithRFC3339String:attributes[@"until"]];
  }
  
  NYPLXML *copiesXML = [linkXML firstChildWithName:@"copies"];
  if (copiesXML) {
    self.availableCopies = [copiesXML.attributes[@"available"] integerValue];
    self.totalCopies = [copiesXML.attributes[@"total"] integerValue];
  }
  
  NYPLXML *holdsXML = [linkXML firstChildWithName:@"holds"];
  if (holdsXML) {
    self.holdsPosition = [holdsXML.attributes[@"position"] integerValue];
  }
  
  [self addAcquisitionFormatsWithXML:linkXML];
  
  return self;
}

- (void)addAcquisitionFormatsWithXML:(NYPLXML *)acquisitionXML
{
  NSArray *children = [acquisitionXML childrenWithName:@"indirectAcquisition"];
  if (children.count > 0) {
    for (NYPLXML *child in children)
      [self addAcquisitionFormatsWithXML:child];
  } else {
    NSDictionary *attributes = acquisitionXML.attributes;
    NSString *acquisitionFormat = attributes[@"type"];
    if (acquisitionFormat)
      [self.mutableAcquisitionFormats addObject:acquisitionFormat];
  }
}

- (NSArray *)acquisitionFormats
{
  return [[NSArray alloc] initWithArray:self.mutableAcquisitionFormats];
}

@end
