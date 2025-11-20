import { LightningElement } from 'lwc';

export default class AttachmentQueryApp extends LightningElement {
    handleQueryResults(event) {
        const { results, fields, objectType } = event.detail;
        
        // Pass results to the display component
        const displayComponent = this.template.querySelector('c-results-display');
        if (displayComponent) {
            displayComponent.updateResults(results, fields, objectType);
        }
    }
}