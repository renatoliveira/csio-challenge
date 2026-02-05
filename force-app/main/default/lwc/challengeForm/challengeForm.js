import { LightningElement } from 'lwc';
import getFormTemplate from '@salesforce/apex/ChallengeFormController.getFormTemplate';
import submitForm from '@salesforce/apex/ChallengeFormController.submitForm';

export default class ChallengeForm extends LightningElement {
    templateData = null;
    formFields = [];
    message = '';
    isError = false;
    isLoading = true;

    get messageThemeClass() {
        if (!this.message) return '';
        return this.isError ? 'slds-theme_error' : 'slds-theme_success';
    }

    get hasFormFields() {
        return this.formFields && this.formFields.length > 0;
    }

    _getInputType(field) {
        const type = (field.type || '').toString().toLowerCase();
        const name = (field.name || '').toString().toLowerCase();
        if (type === 'money') return 'number';
        if (name === 'email') return 'email';
        if (name === 'phone') return 'tel';
        return 'text';
    }

    connectedCallback() {
        this.loadTemplate();
    }

    loadTemplate() {
        this.isLoading = true;
        this.message = '';
        getFormTemplate()
            .then((templateStrOrObj) => {
                const template =
                    typeof templateStrOrObj === 'string'
                        ? JSON.parse(templateStrOrObj)
                        : templateStrOrObj;
                if (!template || typeof template !== 'object' || Array.isArray(template)) {
                    throw new Error('Unexpected template format');
                }
                this.templateData = template;
                this.formFields = Object.keys(template).map((key) => {
                    const field = template[key];
                    const inputType = this._getInputType(field);
                    return {
                        key,
                        ...field,
                        inputType,
                        step: inputType === 'number' ? '0.01' : undefined
                    };
                });
                this.isLoading = false;
                this.message = '';
            })
            .catch((error) => {
                console.error('Error loading form template:', error);
                console.error('Error loading form template:', error.message);
                this.isLoading = false;
                this.message = 'Failed to load form template!';
                this.isError = true;

            });
    }

    handleSubmit() {
        if (!this.templateData) {
            this.message = 'Form template not loaded.';
            this.isError = true;
            return;
        }
        const inputs = this.template.querySelectorAll('lightning-input');
        const valueByName = {};
        inputs.forEach((input) => {
            const name = input.name || input.dataset?.name;
            if (name) {
                let val = input.value;
                if (val != null && typeof val === 'string') val = val.trim();
                valueByName[name] = val || null;
            }
        });
        const payload = {};
        Object.keys(this.templateData).forEach((key) => {
            const field = this.templateData[key];
            payload[key] = {
                label: field.label,
                name: field.name,
                required: field.required,
                type: field.type,
                value: valueByName[field.name] ?? null
            };
        });
        this.message = '';
        submitForm({ requestBody: JSON.stringify(payload) })
            .then((result) => {
                this.message = result.message || (result.success ? 'Form submitted successfully' : 'Form submitted failed');
                this.isError = !result.success;
            })
            .catch(() => {
                this.message = 'Failed to submit form.';
                this.isError = true;
            });
    }
}
