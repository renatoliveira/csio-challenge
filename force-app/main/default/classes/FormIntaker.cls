/**
 * Form intaker should be implemented by the caller on the page and on the webhook endpoint.
 */
public with sharing class FormIntaker {

    private static final String JSON_DATA_REQUIRED_ERROR = 'JSON data is required';
    private static final String INVALID_JSON_DATA_ERROR = 'Invalid JSON data';

    // these are public so they can be reused in tests and in future rule matching implementations
    public static final String NO_MATCHING_RECORD_FOUND_ERROR = 'No matching record found';
    public static final String MISSING_MATCHING_FIELDS_ERROR = 'Matching fields are required';

    public static void processFormData(String jsonData, Type formType) {
        if (String.isBlank(jsonData)) {
            throw new FormDataValidationException(JSON_DATA_REQUIRED_ERROR);
        }

        if (formType == null) {
            formType = DefaultForm.class;
        }

        IForm form;

        try {
            form = (IForm) JSON.deserialize(jsonData, formType);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, INVALID_JSON_DATA_ERROR + ' ' + e.getStackTraceString());
            System.debug(jsonData);
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
            throw new FormDataValidationException(INVALID_JSON_DATA_ERROR);
        }

        // attempt to match existing account
        // and execute actions based on the result
        form.executeActions();
    }

    private static SObject doMatching(IForm form) {
        FormMatcher matcher = new FormMatcher();

        SObject record = matcher.match(new Map<String, FormFieldMatchingRule> {
            'taxId' => new FormFieldMatchingRule(new FormField('Federal Tax ID', 'federal_tax_id', false, FormFieldType.TEXT), Schema.Account.AccountNumber),
            'companyName' => new FormFieldMatchingRule(new FormField('Company Name', 'company_name', true, FormFieldType.TEXT), Schema.Account.Name)
        });

        return record;
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
        public String value { get; set; }

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
            this.value = null;
        }

        public Object getValue() {
            if (this.value == null) {
                return null;
            }

            if (this.type == FormFieldType.TEXT) {
                return this.value;
            }

            return Decimal.valueOf(this.value);
        }

        public void setValue(Object value) {
            if (value == null) {
                this.value = null;
                return;
            }

            if (this.type == FormFieldType.TEXT) {
                this.value = String.valueOf(value);
            }

            this.value = String.valueOf(value);
        }
    }
}