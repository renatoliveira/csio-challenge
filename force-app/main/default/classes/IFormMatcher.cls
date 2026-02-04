public interface IFormMatcher {
    SObject match(Map<String, FormFieldMatchingRule> matchingFields);
}