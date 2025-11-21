import { LightningElement, track, wire } from 'lwc';
import queryAttachments from '@salesforce/apex/AttachmentQueryController.queryAttachments';
import queryContentDocuments from '@salesforce/apex/AttachmentQueryController.queryContentDocuments';
import getObjectFields from '@salesforce/apex/AttachmentQueryController.getObjectFields';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class QueryInput extends LightningElement {
    @track selectedObject = 'Attachment';
    @track selectedFields = [];
    @track whereClause = '';
    @track limitValue = '10';
    @track isLoading = false;
    @track fieldOptions = [];

    objectOptions = [
        { label: 'Attachment', value: 'Attachment' },
        { label: 'ContentDocument', value: 'ContentDocument' }
    ];

    connectedCallback() {
        this.loadFields();
    }

    async loadFields() {
        try {
            const fields = await getObjectFields({ objectName: this.selectedObject });
            this.fieldOptions = fields.map(field => ({
                label: field,
                value: field
            }));
        } catch (error) {
            this.showToast('Error', 'Error loading fields: ' + error.body?.message, 'error');
        }
    }

    async handleObjectChange(event) {
        this.selectedObject = event.detail.value;
        this.selectedFields = []; // Reset fields when object changes
        await this.loadFields(); // Reload fields for new object
    }

    handleFieldChange(event) {
        this.selectedFields = event.detail.value;
    }

    handleWhereChange(event) {
        this.whereClause = event.target.value;
    }

    handleLimitChange(event) {
        this.limitValue = event.target.value;
    }

    async handleQuery() {
        if (this.selectedFields.length === 0) {
            this.showToast('Error', 'Please select at least one field', 'error');
            return;
        }

        this.isLoading = true;

        try {
            let results;
            const params = {
                fields: this.selectedFields.join(','),
                whereClause: this.whereClause,
                limitValue: parseInt(this.limitValue, 10)
            };

            if (this.selectedObject === 'Attachment') {
                results = await queryAttachments(params);
            } else {
                results = await queryContentDocuments(params);
            }

            // Dispatch event to parent with results
            const queryEvent = new CustomEvent('queryresults', {
                detail: {
                    results: results,
                    fields: this.selectedFields,
                    objectType: this.selectedObject
                }
            });
            this.dispatchEvent(queryEvent);

            this.showToast('Success', `Retrieved ${results.length} records`, 'success');
        } catch (error) {
            this.showToast('Error', error.body?.message || 'Error executing query', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}