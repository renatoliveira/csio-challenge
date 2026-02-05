/**
 * Apex controller for the ChallengeForm LWC.
 * Exposes the same form template and submit logic as FormRESTApiService.
 */
public with sharing class ChallengeFormController {

    @AuraEnabled(cacheable=true)
    public static String getFormTemplate() {
        DefaultForm form = new DefaultForm();
        return JSON.serializePretty(form);
    }

    @AuraEnabled
    public static Map<String, Object> submitForm(String requestBody) {
        try {
            FormIntaker.context = 'web';
            FormIntaker.processFormData(requestBody, DefaultForm.class);
            return new Map<String, Object>{
                'success' => true,
                'message' => FormRESTApiService.STATUS_200_FORM_SUBMITTED_SUCCESSFULLY_MESSAGE
            };
        } catch (FormDataValidationException e) {
            return new Map<String, Object>{
                'success' => false,
                'message' => FormRESTApiService.STATUS_400_FORM_SUBMITTED_FAILED_MESSAGE
            };
        } catch (Exception e) {
            return new Map<String, Object>{
                'success' => false,
                'message' => FormRESTApiService.STATUS_500_INTERNAL_SERVER_ERROR_MESSAGE
            };
        }
    }
}
