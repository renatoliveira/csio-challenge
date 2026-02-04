@IsTest
private class FormIntakerTest {

    @IsTest
    static void testSimpleProcess() {
        FormIntaker.DefaultForm form = new FormIntaker.DefaultForm();
        form.companyName.value = 'Test Company';
        form.email.value = 'test@test.com';
        form.phone.value = '1234567890';
        form.contactFirstName.value = 'Test';
        form.contactLastName.value = 'Test';
        form.federalTaxId.value = '1234567890';
        form.annualRevenue.value = 100000;

        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())){
            FormIntaker.processFormData(JSON.serialize(form), form);
        }
        Test.stopTest();
    }
}