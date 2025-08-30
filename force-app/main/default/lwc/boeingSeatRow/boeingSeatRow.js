import { LightningElement, api } from 'lwc';

export default class BoeingSeatRow extends LightningElement {
    @api row;
    @api showHeatMap = false;
    @api seatClass;

    get rowClasses() {
        let classes = 'seat-row';
        if (this.row.isEmergencyRow) {
            classes += ' emergency-row';
        }
        return classes;
    }

    get aisleClass() {
        return this.row.isBusinessClass ? 'aisle business-aisle' : 'aisle';
    }

    get isEmergencyExit() {
        return this.row.isEmergencyRow;
    }
}