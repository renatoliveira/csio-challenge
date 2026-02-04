// Default implementation for the matching, according to the
// original business requirements of tax id (preferred) and company name (fallback)
public class FormMatcher implements IFormMatcher {
    // Three pieces of information: the form field, the object field and the value from the form
    public SObject match(Map<String, FormIntaker.MatchingRule> matchingFields) {
        if (matchingFields == null || matchingFields.isEmpty()) {
            throw new FormIntaker.FormDataValidationException(FormIntaker.MISSING_MATCHING_FIELDS_ERROR);
        }

        String taxId = matchingFields.get('taxId').getFieldFormValueAsString();
        String companyName = matchingFields.get('companyName').getFieldFormValueAsString();

        // Single query, do not spend time on multiple queries
        List<Account> records = [
            SELECT Id, AccountNumber, Name
            FROM Account
            WHERE Name = :companyName
            OR AccountNumber = :taxId
        ];

        if (records.isEmpty()) {
            return null;
        }

        for (Account record : records) {
            // first match to try: tax id
            if (String.isNotBlank(taxId) && taxId == record.AccountNumber) {
                return record;
            }

            // second match to try: company name
            if (String.isNotBlank(companyName) && companyName == record.Name) {
                return record;
            }
        }

        return null;
    }
}