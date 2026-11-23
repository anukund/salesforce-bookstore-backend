@RestResource(urlMapping='/bookstore/v1/*')
global with sharing class BookstoreApi {
    private class Purchase {
        public Id bookId;
        public Integer quantity;
    }

    private static String route() {
        return RestContext.request.requestURI.substringAfter('/bookstore/v1/');
    }

    private static void reply(Integer status, Object body) {
        RestContext.response.statusCode = status;
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(body));
    }

    private static void fail(Integer status, String message) {
        reply(status, new Map<String, Object>{'error' => message});
    }

    @HttpGet
    global static void read() {
        String path = route();
        if (path == 'books') {
            reply(200, [SELECT Id, Name, Price__c, Stock__c FROM Book__c
                        WITH USER_MODE ORDER BY Name, Id LIMIT 100]);
            return;
        }
        if (path.startsWith('orders/')) {
            String key = path.substringAfter('orders/');
            if (Pattern.matches('[a-zA-Z0-9]{15}([a-zA-Z0-9]{3})?', key)) {
                List<Book_Order__c> rows = [SELECT Id, Name, Book__c, Quantity__c, Total__c
                    FROM Book_Order__c WHERE Id = :key WITH USER_MODE LIMIT 1];
                if (!rows.isEmpty()) {
                    reply(200, rows[0]);
                    return;
                }
            }
        }
        fail(404, 'Resource not found');
    }

    @HttpPost
    global static void checkout() {
        if (route() != 'orders') {
            fail(404, 'Resource not found');
            return;
        }
        Purchase input;
        try {
            input = (Purchase)JSON.deserializeStrict(RestContext.request.requestBody.toString(), Purchase.class);
        } catch (Exception e) {
            fail(400, 'Expected bookId and integer quantity');
            return;
        }
        if (input == null || input.bookId == null || input.quantity == null || input.quantity < 1) {
            fail(400, 'Supply a bookId and a positive quantity');
            return;
        }
        List<Book__c> books = [SELECT Id, Price__c, Stock__c FROM Book__c
                               WHERE Id = :input.bookId WITH USER_MODE FOR UPDATE];
        if (books.isEmpty()) {
            fail(404, 'Book not found');
            return;
        }
        Book__c book = books[0];
        if (book.Stock__c < input.quantity) {
            fail(409, 'Insufficient stock');
            return;
        }
        book.Stock__c -= input.quantity;
        Book_Order__c receipt = new Book_Order__c(Book__c=book.Id, Quantity__c=input.quantity,
                                                  Total__c=book.Price__c * input.quantity);
        // Unhandled write failures roll back both operations in this request.
        update as user book;
        insert as user receipt;
        reply(201, new Map<String, Object>{'orderId'=>receipt.Id, 'total'=>receipt.Total__c});
    }
}
