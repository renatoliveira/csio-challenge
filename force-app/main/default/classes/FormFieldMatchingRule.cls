public class FormFieldMatchingRule {
    public FormIntaker.FormField formField;
    public Schema.SObjectField objectField;

    public FormFieldMatchingRule(FormIntaker.FormField formField, Schema.SObjectField objectField) {
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