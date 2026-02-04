@IsTest
public class FormTestingResources {
    public static final String ACCOUNT_TAX_ID = '1234567890';
    public static final String ACCOUNT_NAME = 'Test Company';

    public static DefaultForm createTestContextForm() {
        DefaultForm form = new DefaultForm();
        form.companyName.setValue(ACCOUNT_NAME);
        form.email.setValue('test@test.com');
        form.phone.setValue('+1 555-555-5555');
        form.contactFirstName.setValue('John');
        form.contactLastName.setValue('Doe');
        return form;
    }
}