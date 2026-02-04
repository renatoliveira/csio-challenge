/**
 * Form intaker should be implemented by the caller on the page and on the webhook endpoint.
 */
public with sharing class FormIntaker {

    private static final String JSON_DATA_REQUIRED_ERROR = 'JSON data is required';
    private static final String INVALID_JSON_DATA_ERROR = 'Invalid JSON data';

    // these are public so they can be reused in tests and in future rule matching implementations
    public static final String NO_MATCHING_RECORD_FOUND_ERROR = 'No matching record found';
    public static final String MISSING_MATCHING_FIELDS_ERROR = 'Matching fields are required';

    public static void processFormData(String jsonData, DefaultForm formTemplate) {
        if (String.isBlank(jsonData)) {
            throw new FormDataValidationException(JSON_DATA_REQUIRED_ERROR);
        }

        if (formTemplate == null) {
            throw new FormDataValidationException('Form is required');
        }

        Map<String, Object> dataMap;

        try {
            dataMap = (Map<String, Object>) JSON.deserializeUntyped(jsonData);
            System.debug(dataMap);
        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, INVALID_JSON_DATA_ERROR + ' ' + e.getStackTraceString());
            throw new FormDataValidationException(INVALID_JSON_DATA_ERROR);
        }

        // build form from data provided by the caller
        FormIntaker.IForm form = mapFormFields(dataMap);
        System.debug((FormIntaker.DefaultForm)form);
        System.debug(((FormIntaker.DefaultForm)form).email);

        // attempt to match existing account
        // and execute actions based on the result
        form.executeActions();
    }

    private static DefaultForm mapFormFields(Map<String, Object> dataMap) {
        DefaultForm form = new DefaultForm();

        for (FormField field : form.getFields()) {
            Object raw = dataMap.get(field.name);
            if (raw == null) {
                for (String key : dataMap.keySet()) {
                    Object v = dataMap.get(key);
                    if (v instanceof Map<String, Object>) {
                        Map<String, Object> m = (Map<String, Object>) v;
                        if (field.name.equals(m.get('name'))) {
                            raw = v;
                            break;
                        }
                    }
                }
            }
            if (raw != null) {
                if (raw instanceof Map<String, Object>) {
                    Map<String, Object> fieldMap = (Map<String, Object>) raw;
                    if (fieldMap.containsKey('value')) {
                        field.value = fieldMap.get('value');
                    }
                } else if (raw instanceof FormIntaker.FormField) {
                    field.value = ((FormIntaker.FormField) raw).value;
                }
            }
        }

        return form;
    }

    private static SObject doMatching(FormIntaker.DefaultForm form) {
        FormMatcher matcher = new FormMatcher();

        SObject record = matcher.match(new Map<String, MatchingRule> {
            'taxId' => new MatchingRule(new FormField('Federal Tax ID', 'federal_tax_id', false, FormFieldType.TEXT), Schema.Account.AccountNumber),
            'companyName' => new MatchingRule(new FormField('Company Name', 'company_name', true, FormFieldType.TEXT), Schema.Account.Name)
        });

        return record;
    }

    public interface IForm {
        List<FormField> getFields();
        Object getFieldValue(String fieldName);
        SObject matchToExistingRecord();
        void executeActions();
    }

    public interface IFormActionOnScenario {
        void execute(FormIntaker.IForm form, Map<String, Object> params);
    }

    public class DefaultFormActionOnMatch implements IFormActionOnScenario {
        public void execute(FormIntaker.IForm form, Map<String, Object> params) {
            // create opportunity
            if (!params.containsKey('accountId')) {
                throw new FormDataValidationException('Account ID is required');
            }

            Opportunity opportunity = new Opportunity(
                Name = (String) form.getFieldValue('company_name'),
                AccountId = (Id) params.get('accountId'),
                StageName = 'Prospecting',
                CloseDate = Date.today().addMonths(1)
            );

            insert opportunity;
        }
    }

    public class DefaultFormActionOnNoMatch implements IFormActionOnScenario {
        public void execute(FormIntaker.IForm form, Map<String, Object> params) {
            // create lead
            System.debug(form);
            System.debug(((FormIntaker.DefaultForm)form).email);
            System.debug(params);
            Lead lead = new Lead(
                FirstName = (String) form.getFieldValue('contact_first_name'),
                LastName = (String) form.getFieldValue('contact_last_name'),
                Email = (String) form.getFieldValue('email'),
                Phone = (String) form.getFieldValue('phone'),
                Company = (String) form.getFieldValue('company_name')
            );

            insert lead;
        }
    }

    public class DefaultForm implements IForm {
        public IFormActionOnScenario actionOnMatch = new DefaultFormActionOnMatch();
        public IFormActionOnScenario actionOnNoMatch = new DefaultFormActionOnNoMatch();
        public IFormMatcher matcher = new FormMatcher();

        public FormField companyName = new FormField('Company Name', 'company_name', true, FormFieldType.TEXT);
        public FormField email = new FormField('Email', 'email', true, FormFieldType.TEXT);
        public FormField phone = new FormField('Phone', 'phone', true, FormFieldType.TEXT);

        // optional fields
        public FormField federalTaxId = new FormField('Federal Tax ID', 'federal_tax_id', false, FormFieldType.TEXT);
        public FormField annualRevenue = new FormField('Annual Revenue', 'annual_revenue', false, FormFieldType.MONEY);

        // contact
        public FormField contactFirstName = new FormField('Contact First Name', 'contact_first_name', true, FormFieldType.TEXT);
        public FormField contactLastName = new FormField('Contact Last Name', 'contact_last_name', true, FormFieldType.TEXT);

        public List<FormField> getFields() {
            return new List<FormField> {
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
                    return field.value;
                }
            }

            throw new FormIntaker.FormDataValidationException('Field ' + fieldName + ' does not exist');
        }

        public SObject matchToExistingRecord() {
            return this.matcher.match(new Map<String, MatchingRule> {
                'taxId' => new MatchingRule(this.federalTaxId, Schema.Account.AccountNumber),
                'companyName' => new MatchingRule(this.companyName, Schema.Account.Name)
            });
        }

        public void executeActions() {
            // matching to existing record
            SObject record = this.matchToExistingRecord();

            if (record != null) {
                this.actionOnMatch.execute(this, new Map<String, Object>{ 'accountId' => record.Id });
            } else {
                this.actionOnNoMatch.execute(this, new Map<String, Object>());
            }
        }
    }

    public enum FormFieldType {
        TEXT,
        MONEY
    }

    public class FormField {
        public String label { get; set; }
        public String name { get; set; }
        public Boolean required { get; set; }
        public FormFieldType type { get; set; }
        public Object value { get; set; }

        public FormField(String label, String name, Boolean required, FormFieldType type) {
            if (String.isBlank(label)) {
                throw new FormDataValidationException('Label is required');
            }

            if (String.isBlank(name)) {
                throw new FormDataValidationException('Name is required');
            }

            if (type == null) {
                throw new FormDataValidationException('Type is required');
            }

            if (required == null) {
                throw new FormDataValidationException('Required is required');
            }

            this.label = label;
            this.name = name == null ? label.toLowerCase().replace(' ', '_') : name;
            this.required = required;
            this.type = type;
        }
    }

    public class MatchingRule {
        public FormField formField;
        public Schema.SObjectField objectField;

        public MatchingRule(FormField formField, Schema.SObjectField objectField) {
            if (formField == null) {
                throw new FormDataValidationException('Form field is required');
            }

            if (objectField == null) {
                throw new FormDataValidationException('Object field is required');
            }

            this.formField = formField;
            this.objectField = objectField;
        }

        public String getFieldFormValueAsString() {
            return this.formField?.value == null ? null : String.valueOf(this.formField.value);
        }
    }

    public class FormDataValidationException extends Exception {}
}