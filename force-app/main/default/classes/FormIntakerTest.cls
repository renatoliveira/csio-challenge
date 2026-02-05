@IsTest
private class FormIntakerTest {

    @TestSetup
    static void setup() {
        Account existingAccount = new Account(Name = FormTestingResources.ACCOUNT_NAME, AccountNumber = FormTestingResources.ACCOUNT_TAX_ID);
        insert existingAccount;
    }

    private static DefaultForm createTestContextForm() {
        DefaultForm form = new DefaultForm();
        // form.companyName.name = 'company_name';
        form.companyName.setValue(FormTestingResources.ACCOUNT_NAME);
        // form.email.name = 'email';
        form.email.setValue('test@test.com');
        // form.phone.name = 'phone';
        form.phone.setValue('+1 555-555-5555');
        // form.contactFirstName.name = 'contact_first_name';
        form.contactFirstName.setValue('John');
        // form.contactLastName.name = 'contact_last_name';
        form.contactLastName.setValue('Doe');
        return form;
    }

    /**
     * When an application is submitted:

        - The system must attempt to match an existing Account.
        - If a match is found, an Opportunity is created.
        - If no match is found, a Lead is created.

        ### Matching rules:

        - Prefer matching by Federal Tax ID when available.
        - Fall back to Company Name if no Tax ID is provided.
        - Each created record must indicate where it came from (Community, Webhook)
     */

    @IsTest
    static void testMatchByCompanyName() { // matches by company name
        DefaultForm form = createTestContextForm();
        form.companyName.setValue(FormTestingResources.ACCOUNT_NAME);

        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())){
            FormIntaker.processFormData(JSON.serialize(form), DefaultForm.class);
        }
        Test.stopTest();

        // Match found (Account with same Tax ID): Opportunity created, no Lead
        Assert.areEqual(1, [SELECT COUNT() FROM Opportunity], 'Expected one Opportunity when account matches');
        Assert.areEqual(0, [SELECT COUNT() FROM Lead], 'Expected no Lead when account matches');
        Assert.areEqual('Other', [SELECT LeadSource FROM Opportunity].LeadSource, 'Expected LeadSource to be "Other"');
    }

    @IsTest
    static void testMatchByTaxId() { // matches by tax id
        DefaultForm form = createTestContextForm();
        form.federalTaxId.setValue(FormTestingResources.ACCOUNT_TAX_ID);
        form.companyName.setValue('Company That Does Not Exist, Co.');

        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())){
            FormIntaker.processFormData(JSON.serialize(form), DefaultForm.class);
        }
        Test.stopTest();

        // Match found (Account with same Tax ID): Opportunity created, no Lead
        Assert.areEqual(1, [SELECT COUNT() FROM Opportunity], 'Expected one Opportunity when account matches');
        Assert.areEqual(0, [SELECT COUNT() FROM Lead], 'Expected no Lead when account matches');
        Assert.areEqual('Other', [SELECT LeadSource FROM Opportunity].LeadSource, 'Expected LeadSource to be "Other"');
    }

    @IsTest
    static void testAttemptToMatchToNonExistingAccount() { // no match found, creates lead
        DefaultForm form = createTestContextForm();
        form.companyName.setValue('Non-existing Company');
        form.federalTaxId.setValue(null);

        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())){
            FormIntaker.processFormData(JSON.serialize(form), DefaultForm.class);
        }
        Test.stopTest();

        // No match found, Lead created
        Assert.areEqual(0, [SELECT COUNT() FROM Opportunity], 'Expected no Opportunity when no account matches');
        Assert.areEqual(1, [SELECT COUNT() FROM Lead], 'Expected one Lead when no account matches');
        Assert.areEqual('Other', [SELECT LeadSource FROM Lead].LeadSource, 'Expected LeadSource to be "Other"');
    }

    @IsTest
    static void testAttemptToProcessFormDataWithNoFormType() {
        DefaultForm form = createTestContextForm();
        FormDataValidationException exceptionThrown;

        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())){
            try {
                FormIntaker.processFormData(JSON.serialize(form), null);
            } catch (FormDataValidationException e) {
                exceptionThrown = e;
            }
        }
        Test.stopTest();

        Assert.isNotNull(exceptionThrown, 'Expected FormDataValidationException to be thrown');
        Assert.areEqual(FormIntaker.FORM_TYPE_REQUIRED_ERROR, exceptionThrown.getMessage(), 'Expected FormDataValidationException to be thrown with the correct message');
        Assert.areEqual(0, [SELECT COUNT() FROM Opportunity], 'Expected no Opportunity when no form type is provided');
        Assert.areEqual(0, [SELECT COUNT() FROM Lead], 'Expected no Lead when no form type is provided');
    }
}