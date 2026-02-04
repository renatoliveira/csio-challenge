@IsTest
private class FormIntakerTest {

    private static String ACCOUNT_TAX_ID = '1234567890';
    private static String ACCOUNT_NAME = 'Test Company';

    @TestSetup
    static void setup() {
        Account existingAccount = new Account(Name = ACCOUNT_NAME, AccountNumber = ACCOUNT_TAX_ID);
        insert existingAccount;
    }

    private static DefaultForm createTestContextForm() {
        DefaultForm form = new DefaultForm();
        // form.companyName.name = 'company_name';
        form.companyName.setValue(ACCOUNT_NAME);
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
        form.companyName.setValue(ACCOUNT_NAME);

        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())){
            FormIntaker.processFormData(JSON.serialize(form), DefaultForm.class);
        }
        Test.stopTest();

        // Match found (Account with same Tax ID): Opportunity created, no Lead
        System.assertEquals(1, [SELECT COUNT() FROM Opportunity], 'Expected one Opportunity when account matches');
        System.assertEquals(0, [SELECT COUNT() FROM Lead], 'Expected no Lead when account matches');
    }

    @IsTest
    static void testMatchByTaxId() { // matches by tax id
        DefaultForm form = createTestContextForm();
        form.federalTaxId.setValue(ACCOUNT_TAX_ID);
        form.companyName.setValue('Company That Does Not Exist, Co.');

        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())){
            FormIntaker.processFormData(JSON.serialize(form), DefaultForm.class);
        }
        Test.stopTest();

        // Match found (Account with same Tax ID): Opportunity created, no Lead
        System.assertEquals(1, [SELECT COUNT() FROM Opportunity], 'Expected one Opportunity when account matches');
        System.assertEquals(0, [SELECT COUNT() FROM Lead], 'Expected no Lead when account matches');
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
        System.assertEquals(0, [SELECT COUNT() FROM Opportunity], 'Expected no Opportunity when no account matches');
        System.assertEquals(1, [SELECT COUNT() FROM Lead], 'Expected one Lead when no account matches');
    }
}