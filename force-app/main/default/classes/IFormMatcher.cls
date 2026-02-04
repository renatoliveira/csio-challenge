public interface IFormMatcher {
    SObject match(Map<String, FormIntaker.MatchingRule> matchingFields);
}