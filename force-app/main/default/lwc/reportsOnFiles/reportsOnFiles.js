/**
 * @description Container component for the Reporting on Files application.
 *              Enhanced to forward field labels from queryBuilder to resultsDisplay.
 * 
 * @author Mritesh
 * @date 2026-02-17
 * @version 1.2.0
 */
import { LightningElement } from 'lwc';

export default class ReportsOnFiles extends LightningElement {
    /**
     * @description Handles query results from queryBuilder and passes them to resultsDisplay.
     *              Now includes fieldLabels for displaying column headers with labels.
     * @param {CustomEvent} event - Event containing results, fields, objectType, and fieldLabels
     */
    handleQueryResults(event) {
        const { results, fields, objectType, fieldLabels } = event.detail;
        
        // Pass results and field labels to the display component
        const displayComponent = this.template.querySelector('c-results-display');
        if (displayComponent) {
            displayComponent.updateResults(results, fields, objectType, fieldLabels);
        }
    }
}