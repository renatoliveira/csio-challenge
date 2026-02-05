@IsTest
private class FormRESTApiServiceTest {

    @TestSetup
    static void setup() {
        Account existingAccount = new Account(Name = FormTestingResources.ACCOUNT_NAME, AccountNumber = FormTestingResources.ACCOUNT_TAX_ID);
        insert existingAccount;
    }

    @IsTest
    static void testGetFormTemplate() {
        // create a test request
        RestRequest request = new RestRequest();
        request.requestUri = 'https://www.example.com/services/apexrest/v1/form/template';
        request.httpMethod = 'GET';

        // submit the form
        Test.startTest();
        RestContext.request = request;
        RestContext.response = new RestResponse();
        System.runAs(new User(Id = UserInfo.getUserId())){
            FormRESTApiService.getFormTemplate();
        }
        RestResponse response = RestContext.response;
        Test.stopTest();

        // assert the response
        Assert.areEqual(200, response.statusCode, 'Expected status code to be 200');
        Assert.areEqual(JSON.serializePretty(new DefaultForm()), response.responseBody.toString(), 'Expected response body to be the empty form JSON template');
    }

    @IsTest
    static void testSubmitFormWithCompanyNameMatch() {
        DefaultForm form = FormTestingResources.createTestContextForm();
        form.federalTaxId.setValue(null);
        form.companyName.setValue(FormTestingResources.ACCOUNT_NAME);
        String requestBody = JSON.serialize(form);

        // create a test request
        RestRequest request = new RestRequest();
        request.requestUri = 'https://www.example.com/services/apexrest/v1/form/submit';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(requestBody);

        // submit the form
        Test.startTest();
        RestContext.request = request;
        RestContext.response = new RestResponse();
        System.runAs(new User(Id = UserInfo.getUserId())){
            FormRESTApiService.submitForm();
        }
        RestResponse response = RestContext.response;
        Test.stopTest();

        // assert the response
        Assert.areEqual(200, response.statusCode, 'Expected status code to be 200');
        Assert.areEqual(JSON.serialize(new Map<String, Object>{'message' => 'Form submitted successfully'}), response.responseBody.toString(), 'Expected response body to be "Form submitted successfully"');

        // assert the opportunity was created
        Assert.areEqual(1, [SELECT COUNT() FROM Opportunity], 'Expected one Opportunity when account matches');
        Assert.areEqual(0, [SELECT COUNT() FROM Lead], 'Expected no Lead when account matches');
        Assert.areEqual('api', [SELECT LeadSource FROM Opportunity].LeadSource, 'Expected LeadSource to be "api"');
    }

    @IsTest
    static void testSubmitFormWithTaxIdMatch() {
        DefaultForm form = FormTestingResources.createTestContextForm();
        form.federalTaxId.setValue(FormTestingResources.ACCOUNT_TAX_ID);
        form.companyName.setValue('Company That Does Not Exist, Co.');
        String requestBody = JSON.serialize(form);

        // create a test request
        RestRequest request = new RestRequest();
        request.requestUri = 'https://www.example.com/services/apexrest/v1/form/submit';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(requestBody);

        // submit the form
        Test.startTest();
        RestContext.request = request;
        RestContext.response = new RestResponse();
        System.runAs(new User(Id = UserInfo.getUserId())){
            FormRESTApiService.submitForm();
        }
        RestResponse response = RestContext.response;
        Test.stopTest();

        // assert the response
        Assert.areEqual(200, response.statusCode, 'Expected status code to be 200');
        Assert.areEqual(JSON.serialize(new Map<String, Object>{'message' => 'Form submitted successfully'}), response.responseBody.toString(), 'Expected response body to be "Form submitted successfully"');

        // assert the opportunity was created
        Assert.areEqual(1, [SELECT COUNT() FROM Opportunity], 'Expected one Opportunity when account matches');
        Assert.areEqual(0, [SELECT COUNT() FROM Lead], 'Expected no Lead when account matches');
        Assert.areEqual('api', [SELECT LeadSource FROM Opportunity].LeadSource, 'Expected LeadSource to be "api"');
    }

    @IsTest
    static void testSubmitFormWithNoMatch() {
        DefaultForm form = FormTestingResources.createTestContextForm();
        form.federalTaxId.setValue(null);
        form.companyName.setValue('Company That Does Not Exist, Co.');
        String requestBody = JSON.serialize(form);

        // create a test request
        RestRequest request = new RestRequest();
        request.requestUri = 'https://www.example.com/services/apexrest/v1/form/submit';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(requestBody);

        // submit the form
        Test.startTest();
        RestContext.request = request;
        RestContext.response = new RestResponse();
        System.runAs(new User(Id = UserInfo.getUserId())){
            FormRESTApiService.submitForm();
        }
        RestResponse response = RestContext.response;
        Test.stopTest();

        // assert the response
        Assert.areEqual(200, response.statusCode, 'Expected status code to be 200');
        Assert.areEqual(JSON.serialize(new Map<String, Object>{'message' => 'Form submitted successfully'}), response.responseBody.toString(), 'Expected response body to be "Form submitted successfully"');

        // assert the lead was created
        Assert.areEqual(0, [SELECT COUNT() FROM Opportunity], 'Expected no Opportunity when no account matches');
        Assert.areEqual(1, [SELECT COUNT() FROM Lead], 'Expected one Lead when no account matches');
        Assert.areEqual('api', [SELECT LeadSource FROM Lead].LeadSource, 'Expected LeadSource to be "api"');
    }

    @IsTest
    static void testSubmitInvalidForm() {
        String requestBody = 'invalid json';
        RestRequest request = new RestRequest();
        request.requestUri = 'https://www.example.com/services/apexrest/v1/form/submit';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(requestBody);

        // submit the form
        Test.startTest();
        RestContext.request = request;
        RestContext.response = new RestResponse();
        System.runAs(new User(Id = UserInfo.getUserId())){
            FormRESTApiService.submitForm();
        }
        RestResponse response = RestContext.response;
        Test.stopTest();

        // assert the response
        Assert.areEqual(400, response.statusCode, 'Expected status code to be 400');
        Assert.areEqual(JSON.serialize(new Map<String, Object>{'message' => 'Form submitted failed'}), response.responseBody.toString(), 'Expected response body to be "Form submitted failed"');

        // assert the opportunity and the lead were not created
        Assert.areEqual(0, [SELECT COUNT() FROM Opportunity], 'Expected no Opportunity when invalid form is submitted');
        Assert.areEqual(0, [SELECT COUNT() FROM Lead], 'Expected no Lead when invalid form is submitted');
    }
}