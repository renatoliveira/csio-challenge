@IsTest
private class FormIntakerTest {

    private static String ACCOUNT_TAX_ID = '1234567890';

    @TestSetup
    static void setup() {
        Account existingAccount = new Account(Name = 'Test Company', AccountNumber = '1234567890');
        insert existingAccount;
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
     static void testAttemptToMatchExistingAccount() {
        FormIntaker.DefaultForm form = new FormIntaker.DefaultForm();
        form.companyName.name = 'company_name';
        form.companyName.value = 'Test Company';
        form.email.name = 'email';
        form.email.value = 'test@test.com';
        form.phone.name = 'phone';
        form.phone.value = ACCOUNT_TAX_ID;
        form.contactFirstName.name = 'contact_first_name';
        form.contactFirstName.value = 'Test';
        form.contactLastName.name = 'contact_last_name';
        form.contactLastName.value = 'Test';
        form.federalTaxId.name = 'federal_tax_id';
        form.federalTaxId.value = ACCOUNT_TAX_ID;
        form.annualRevenue.name = 'annual_revenue';
        form.annualRevenue.value = 100000;

        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())){
            FormIntaker.processFormData(JSON.serialize(form), new FormIntaker.DefaultForm());
        }
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM Opportunity]);
        System.assertEquals(1, [SELECT COUNT() FROM Lead]);
    }
}