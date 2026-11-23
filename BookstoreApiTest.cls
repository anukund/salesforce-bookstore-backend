@IsTest
private class BookstoreApiTest {
    @TestSetup static void setup() {
        insert new Book__c(Name='The Clockwork Library', Price__c=12.99, Stock__c=5);
    }

    private static Integer invoke(String method, String path, Object payload) {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/bookstore/v1/' + path;
        req.httpMethod = method;
        req.requestBody = Blob.valueOf(JSON.serialize(payload));
        RestContext.request = req;
        RestContext.response = new RestResponse();
        if (method == 'GET') BookstoreApi.read();
        else BookstoreApi.checkout();
        return RestContext.response.statusCode;
    }

    @IsTest static void purchaseAndRetrieve() {
        Book__c book = [SELECT Id FROM Book__c LIMIT 1];
        System.assertEquals(200, invoke('GET','books',null));
        System.assertEquals(201, invoke('POST','orders',new Map<String,Object>{'bookId'=>book.Id,'quantity'=>2}));
        Map<String,Object> body = (Map<String,Object>)JSON.deserializeUntyped(RestContext.response.responseBody.toString());
        System.assertEquals(25.98, (Decimal)body.get('total'));
        System.assertEquals(200, invoke('GET','orders/'+body.get('orderId'),null));
        Book_Order__c receipt = (Book_Order__c)JSON.deserialize(RestContext.response.responseBody.toString(), Book_Order__c.class);
        System.assertEquals(book.Id, receipt.Book__c);
        System.assertEquals(2, receipt.Quantity__c);
        System.assertEquals(3, [SELECT Stock__c FROM Book__c LIMIT 1].Stock__c);
    }

    @IsTest static void rejectedPurchases() {
        Id book = [SELECT Id FROM Book__c LIMIT 1].Id;
        System.assertEquals(409, invoke('POST','orders',new Map<String,Object>{'bookId'=>book,'quantity'=>6}));
        System.assertEquals(400, invoke('POST','orders',new Map<String,Object>{'bookId'=>book,'quantity'=>0}));
        System.assertEquals(404, invoke('GET','orders/missing',null));
        System.assertEquals(0, [SELECT count() FROM Book_Order__c]);
        System.assertEquals(5, [SELECT Stock__c FROM Book__c LIMIT 1].Stock__c);
    }
}
