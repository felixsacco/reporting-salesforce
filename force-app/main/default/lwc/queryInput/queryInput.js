import { LightningElement, track, wire } from 'lwc';
import queryAttachments from '@salesforce/apex/AttachmentQueryController.queryAttachments';
import queryContentDocuments from '@salesforce/apex/AttachmentQueryController.queryContentDocuments';
import getObjectFields from '@salesforce/apex/AttachmentQueryController.getObjectFields';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class QueryInput extends LightningElement {
    @track selectedObject = 'Attachment';
    @track selectedFields = [];
    @track whereConditions = [];
    @track limitValue = '';
    @track isLoading = false;
    @track fieldOptions = [];

    objectOptions = [
        { label: 'Attachment', value: 'Attachment' },
        { label: 'ContentDocument', value: 'ContentDocument' }
    ];

    operatorOptions = [
        { label: 'Equals', value: '=' },
        { label: 'Not Equals', value: '!=' },
        { label: 'Greater Than', value: '>' },
        { label: 'Greater or Equal', value: '>=' },
        { label: 'Less Than', value: '<' },
        { label: 'Less or Equal', value: '<=' },
        { label: 'Like', value: 'LIKE' },
        { label: 'IN', value: 'IN' },
        { label: 'NOT IN', value: 'NOT IN' }
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
        this.whereConditions = [];
        await this.loadFields(); // Reload fields for new object
    }

    handleFieldChange(event) {
        this.selectedFields = event.detail.value;
    }

    handleAddCondition() {
        const newCondition = {
            id: Date.now(),
            field: '',
            operator: '=',
            value: ''
        };
        this.whereConditions = [...this.whereConditions, newCondition];
    }

    handleRemoveCondition(event) {
        const conditionId = parseInt(event.currentTarget.dataset.id);
        this.whereConditions = this.whereConditions.filter(cond => cond.id !== conditionId);
    }

    handleConditionFieldChange(event) {
        const conditionId = parseInt(event.currentTarget.dataset.id);
        const updatedConditions = this.whereConditions.map(cond => {
            if (cond.id === conditionId) {
                return { ...cond, field: event.detail.value };
            }
            return cond;
        });
        this.whereConditions = updatedConditions;
    }

    handleConditionOperatorChange(event) {
        const conditionId = parseInt(event.currentTarget.dataset.id);
        const updatedConditions = this.whereConditions.map(cond => {
            if (cond.id === conditionId) {
                return { ...cond, operator: event.detail.value };
            }
            return cond;
        });
        this.whereConditions = updatedConditions;
    }

    handleConditionValueChange(event) {
        const conditionId = parseInt(event.currentTarget.dataset.id);
        const updatedConditions = this.whereConditions.map(cond => {
            if (cond.id === conditionId) {
                return { ...cond, value: event.target.value };
            }
            return cond;
        });
        this.whereConditions = updatedConditions;
    }

    buildWhereClause() {
        if (this.whereConditions.length === 0) {
            return '';
        }

        const conditions = this.whereConditions
            .filter(cond => cond.field && cond.value)
            .map(cond => {
                let value = cond.value;
                
                // Handle different operators
                if (cond.operator === 'LIKE') {
                    value = `'%${value}%'`;
                } else if (cond.operator === 'IN' || cond.operator === 'NOT IN') {
                    // Assume comma-separated values
                    const values = value.split(',').map(v => `'${v.trim()}'`).join(',');
                    return `${cond.field} ${cond.operator} (${values})`;
                } else {
                    // Check if value is numeric
                    if (isNaN(value)) {
                        value = `'${value}'`;
                    }
                }
                
                return `${cond.field} ${cond.operator} ${value}`;
            });

        return conditions.join(' AND ');
    }

    get hasConditions() {
        return this.whereConditions.length > 0;
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
            const whereClause = this.buildWhereClause();
            const params = {
                fields: this.selectedFields.join(','),
                whereClause: whereClause,
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