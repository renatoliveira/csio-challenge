public interface IForm {
    List<FormIntaker.FormField> getFields();
    Object getFieldValue(String fieldName);
    SObject matchToExistingRecord();
    void executeActions();
}