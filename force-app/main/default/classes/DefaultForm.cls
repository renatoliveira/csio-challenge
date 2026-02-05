
public class DefaultForm implements IForm {
    public transient IFormActionOnScenario actionOnMatch = new DefaultForm.DefaultFormActionOnMatch();
    public transient IFormActionOnScenario actionOnNoMatch = new DefaultForm.DefaultFormActionOnNoMatch();
    public transient IFormMatcher matcher = new FormMatcher();

    public FormIntaker.FormField companyName = new FormIntaker.FormField('Company Name', 'company_name', true, FormIntaker.FormFieldType.TEXT);
    public FormIntaker.FormField email = new FormIntaker.FormField('Email', 'email', true, FormIntaker.FormFieldType.TEXT);
    public FormIntaker.FormField phone = new FormIntaker.FormField('Phone', 'phone', true, FormIntaker.FormFieldType.TEXT);

    // optional fields
    public FormIntaker.FormField federalTaxId = new FormIntaker.FormField('Federal Tax ID', 'federal_tax_id', false, FormIntaker.FormFieldType.TEXT);
    public FormIntaker.FormField annualRevenue = new FormIntaker.FormField('Annual Revenue', 'annual_revenue', false, FormIntaker.FormFieldType.MONEY);

    // contact
    public FormIntaker.FormField contactFirstName = new FormIntaker.FormField('Contact First Name', 'contact_first_name', true, FormIntaker.FormFieldType.TEXT);
    public FormIntaker.FormField contactLastName = new FormIntaker.FormField('Contact Last Name', 'contact_last_name', true, FormIntaker.FormFieldType.TEXT);

    // because the attributes are transient, we need to initialize them
    private void usingDefaults() {
        this.actionOnMatch = new DefaultForm.DefaultFormActionOnMatch();
        this.actionOnNoMatch = new DefaultForm.DefaultFormActionOnNoMatch();
        this.matcher = new FormMatcher();
    }

    private void validateRequiredFieldsAreSet() {
        for (FormIntaker.FormField field : this.getFields()) {
            if (field.required && field.value == null) {
                throw new FormDataValidationException('Field ' + field.label + ' is required');
            }
        }
    }

    public List<FormIntaker.FormField> getFields() {
        return new List<FormIntaker.FormField> {
            companyName,
            contactFirstName,
            contactLastName,
            email,
            phone,
            federalTaxId,
            annualRevenue
        };
    }

    public Object getFieldValue(String fieldName) {
        List<FormIntaker.FormField> fields = this.getFields();

        for (FormIntaker.FormField field : fields) {
            if (field.name.equals(fieldName)) {
                if (field.type == FormIntaker.FormFieldType.MONEY) {
                    return Decimal.valueOf(field.value);
                } else {
                    return field.value;
                }
            }
        }

        throw new FormDataValidationException('Field ' + fieldName + ' does not exist');
    }

    public SObject matchToExistingRecord() {
        return this.matcher?.match(new Map<String, FormFieldMatchingRule> {
            'taxId' => new FormFieldMatchingRule(this.federalTaxId, Schema.Account.AccountNumber),
            'companyName' => new FormFieldMatchingRule(this.companyName, Schema.Account.Name)
        });
    }

    public void executeActions() {
        this.usingDefaults();
        this.validateRequiredFieldsAreSet();

        // matching to existing record
        SObject record = this.matchToExistingRecord();

        if (record != null) {
            this.actionOnMatch.execute(this, new Map<String, Object>{ 'accountId' => record.Id });
        } else {
            this.actionOnNoMatch.execute(this, new Map<String, Object>());
        }
    }

    public class DefaultFormActionOnMatch implements IFormActionOnScenario {
        public void execute(IForm form, Map<String, Object> params) {
            // create opportunity
            if (!params.containsKey('accountId')) {
                throw new FormDataValidationException('Account ID is required');
            }

            Opportunity opportunity = new Opportunity(
                Name = (String) form.getFieldValue('company_name'),
                AccountId = (Id) params.get('accountId'),
                StageName = 'Prospecting',
                CloseDate = Date.today().addMonths(1),
                LeadSource = FormIntaker.context
            );

            insert opportunity;
        }
    }

    public class DefaultFormActionOnNoMatch implements IFormActionOnScenario {
        public void execute(IForm form, Map<String, Object> params) {
            // create lead
            Lead lead = new Lead(
                FirstName = (String) form.getFieldValue('contact_first_name'),
                LastName = (String) form.getFieldValue('contact_last_name'),
                Email = (String) form.getFieldValue('email'),
                Phone = (String) form.getFieldValue('phone'),
                Company = (String) form.getFieldValue('company_name'),
                AnnualRevenue = (Decimal) form.getFieldValue('annual_revenue'),
                LeadSource = FormIntaker.context
            );

            insert lead;
        }
    }
}