import { LightningElement, track } from 'lwc';
import queryAttachments from '@salesforce/apex/AttachmentQueryController.queryAttachments';
import queryContentDocuments from '@salesforce/apex/AttachmentQueryController.queryContentDocuments';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class QueryInput extends LightningElement {
    @track selectedObject = 'Attachment';
    @track selectedFields = [];
    @track whereClause = '';
    @track limitValue = '';
    @track isLoading = false;

    objectOptions = [
        { label: 'Attachment', value: 'Attachment' },
        { label: 'ContentDocument', value: 'ContentDocument' }
    ];

    attachmentFieldOptions = [
        { label: 'Id', value: 'Id' },
        { label: 'Name', value: 'Name' },
        { label: 'ContentType', value: 'ContentType' },
        { label: 'BodyLength', value: 'BodyLength' },
        { label: 'ParentId', value: 'ParentId' },
        { label: 'CreatedDate', value: 'CreatedDate' },
        { label: 'CreatedById', value: 'CreatedById' },
        { label: 'LastModifiedDate', value: 'LastModifiedDate' }
    ];

    contentDocumentFieldOptions = [
        { label: 'Id', value: 'Id' },
        { label: 'Title', value: 'Title' },
        { label: 'FileType', value: 'FileType' },
        { label: 'ContentSize', value: 'ContentSize' },
        { label: 'CreatedDate', value: 'CreatedDate' },
        { label: 'CreatedById', value: 'CreatedById' },
        { label: 'LastModifiedDate', value: 'LastModifiedDate' },
        { label: 'OwnerId', value: 'OwnerId' }
    ];

    get fieldOptions() {
        return this.selectedObject === 'Attachment' 
            ? this.attachmentFieldOptions 
            : this.contentDocumentFieldOptions;
    }

    handleObjectChange(event) {
        this.selectedObject = event.detail.value;
        this.selectedFields = []; // Reset fields when object changes
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