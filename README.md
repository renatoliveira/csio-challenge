# Salesforce Application Intake - Design & Implementation Exercise

Rely on Salesforce to validate the form structure through JSON serialization
Assuming that the lead and opportunity are the objects being created and that creation of other objects in the future (extending th feature) isn't required, but if it is it will be deferred to using record-triggered flows on these two entities instead.

## Realizations!

This test was about handling the generic "Object" with JSON deserialization, right?

## Assumptions

- Both form and endpoint will be open to the internet (no authentication).
- To add more forms/endpoints, a developer will be needed to add the corresponding classes and logic to handle the new form and endpoint.

## Possibilities for Future Improvements

- The shape of the form could be dynamic based on records (actual custom objects defining the payload and its fields or custom metadata types) to allow for more flexibility in the form structure, and for adding more forms/endpoints as needed without having to modify the code.
- The form could be submitted to a queueable job to improve performance, but that would imply returning a "201 Created" status code instead of "200 OK" to indicate that the request has been accepted for processing, and possibly return a job ID to the client to allow for polling the status of the job. Or this could be a "fire and forget" kind of thing where the client is not interested in the status of the job (suitable for the webhook use case).

## Questions

>Q: Why did you go with this deserialization approach, not having a simple payload object with attributes and values? That is: why have multiple attributes of each being their own object with name, label, value, etc.?

This approach was chosen because the payload format was not specified and there was the time constraint to deliver a solution that works and that can be extended in the future. In practice, with more time, a simple payload object with attributes could be used too, now that I think about it. However, more time would be spent around the deserialization and validation of the payload.

>Q: Where did you get this idea for getting the template form JSON from the back end and then using it to render the form in the front end?

Initially I thought about designing three different components for this build, the frontend part, the backend part (API) and the core implementation of the form intaker. To do this, I started with the core, and then moved to the API. After finishing these two and starting the front end, I played a bit with implementing it with Visualforce instead (because for some reason I forgot about the requirement being LWC). During this writing, as soon as I started to write the `<form>` tag I realized that I could set the endpoint to post the data to, and that I could also make changes to that before the actual submission. So I decided to reuse the backend then for that frontend piece. After realizing that I had wasted my time with Visualforce, I went back to the LWC and implemented it in a similar manner, except I had to also write a controller to handle both the GET and POST requests due to how the Lightning Component framework works.
