if ([SELECT COUNT() FROM Book__c WHERE Name='The Clockwork Library'] == 0) {
    insert new Book__c(Name='The Clockwork Library', Price__c=12.99, Stock__c=5);
}
