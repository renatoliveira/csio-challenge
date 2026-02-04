/**
 * Apex REST service to handle the submission of the form from the external system
 * Callable from the URL at /services/apexrest/v1/form/submit
 */
@RestResource(urlMapping='/v1/form/submit')
global with sharing class FormRESTApiService {

    public static final String STATUS_200_FORM_SUBMITTED_SUCCESSFULLY_MESSAGE = 'Form submitted successfully';
    public static final String STATUS_400_FORM_SUBMITTED_FAILED_MESSAGE = 'Form submitted failed';
    public static final String STATUS_500_INTERNAL_SERVER_ERROR_MESSAGE = 'Internal server error';

    @HttpPost
    global static void submitForm() {
        // get the request body
        String requestBody = RestContext.request.requestBody.toString();

        try {
            FormIntaker.processFormData(requestBody, DefaultForm.class);
        } catch (FormDataValidationException e) {
            RestContext.response.statusCode = 400;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                'message' => STATUS_400_FORM_SUBMITTED_FAILED_MESSAGE
            }));
            return;
        } catch (Exception e) {
            RestContext.response.statusCode = 500;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                'message' => STATUS_500_INTERNAL_SERVER_ERROR_MESSAGE
            }));
            return;
        }

        RestContext.response.statusCode = 200;
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
            'message' => STATUS_200_FORM_SUBMITTED_SUCCESSFULLY_MESSAGE
        }));
    }

    /**
     * Returns the empty form JSON template (ie: the form with no values)
     */
    @HttpGet
    global static void getFormTemplate() {
        DefaultForm form = new DefaultForm();
        RestContext.response.statusCode = 200;
        RestContext.response.responseBody = Blob.valueOf(JSON.serializePretty(form));
    }
}