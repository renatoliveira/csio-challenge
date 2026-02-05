@IsTest
private class ChallengeFormControllerTest {

    @TestSetup
    static void setup() {
        Account existingAccount = new Account(Name = FormTestingResources.ACCOUNT_NAME, AccountNumber = FormTestingResources.ACCOUNT_TAX_ID);
        insert existingAccount;
    }

    @IsTest
    static void testGetFormTemplate() {
        Test.startTest();
        String template = ChallengeFormController.getFormTemplate();
        Test.stopTest();

        Assert.isNotNull(template, 'Expected non-null template');
        Assert.isTrue(template.length() > 0, 'Expected non-empty template');
        Assert.areEqual(JSON.serializePretty(new DefaultForm()), template, 'Expected template to match DefaultForm serialization');
    }

    @IsTest
    static void testSubmitFormValid() {
        DefaultForm form = FormTestingResources.createTestContextForm();
        form.companyName.setValue('Company That Does Not Exist, Co.');
        form.federalTaxId.setValue(null);
        String requestBody = JSON.serialize(form);

        Test.startTest();
        Map<String, Object> result = ChallengeFormController.submitForm(requestBody);
        Test.stopTest();

        Assert.isTrue((Boolean) result.get('success'), 'Expected success to be true');
        Assert.areEqual(FormRESTApiService.STATUS_200_FORM_SUBMITTED_SUCCESSFULLY_MESSAGE, result.get('message'), 'Expected success message');
        Assert.areEqual(1, [SELECT COUNT() FROM Lead], 'Expected one Lead when no account matches');
        Assert.areEqual('web', [SELECT LeadSource FROM Lead].LeadSource, 'Expected LeadSource to be "web"');
    }

    @IsTest
    static void testSubmitFormInvalid() {
        String requestBody = 'invalid json';

        Test.startTest();
        Map<String, Object> result = ChallengeFormController.submitForm(requestBody);
        Test.stopTest();

        Assert.isFalse((Boolean) result.get('success'), 'Expected success to be false');
        Assert.areEqual(FormRESTApiService.STATUS_400_FORM_SUBMITTED_FAILED_MESSAGE, result.get('message'), 'Expected failure message');
        Assert.areEqual(0, [SELECT COUNT() FROM Lead], 'Expected no Lead when invalid form is submitted');
        Assert.areEqual(0, [SELECT COUNT() FROM Opportunity], 'Expected no Opportunity when invalid form is submitted');
    }
}