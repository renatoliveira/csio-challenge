/**
 * Form intaker should be implemented by the caller on the page and on the webhook endpoint.
 */
public with sharing class FormIntaker {

    private static final String JSON_DATA_REQUIRED_ERROR = 'JSON data is required';
    private static final String INVALID_JSON_DATA_ERROR = 'Invalid JSON data.';

    public static void processFormData(String jsonData, DefaultForm form) {
        if (String.isBlank(jsonData)) {
            throw new FormDataValidationException(JSON_DATA_REQUIRED_ERROR);
        }

        if (form == null) {
            throw new FormDataValidationException('Form is required');
        }

        try {
            Map<String, Object> dataMap = (Map<String, Object>) JSON.deserializeUntyped(jsonData);
        }
        catch (Exception e) {
            System.debug(LoggingLevel.ERROR, INVALID_JSON_DATA_ERROR + ' ' + e.getStackTraceString());
            throw new FormDataValidationException(INVALID_JSON_DATA_ERROR);
        }
    }

    private static DefaultForm mapFormFields(Map<String, Object> dataMap) {
        DefaultForm form = new DefaultForm();

        for (FormField field : form.getFields()) {
            if (dataMap.containsKey(field.name)) {
                field.value = dataMap.get(field.name);
            }
        }

        return form;
    }

    public interface IForm {
        List<FormField> getFields();
    }

    public class DefaultForm implements IForm {
        public FormField companyName = new  FormField('Company Name', 'company_name', true, FormFieldType.TEXT);
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
                email,
                phone,
                federalTaxId,
                annualRevenue
            };
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

    public class FormDataValidationException extends Exception {}
}