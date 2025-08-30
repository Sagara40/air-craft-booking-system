import { LightningElement, api } from 'lwc';

export default class BoeingSeat extends LightningElement {
    @api seat;
    @api showHeatMap = false;

    handleClick() {
        if (this.seat.isAvailable) {
            this.dispatchEvent(new CustomEvent('seatclick', {
                detail: { seatId: this.seat.id },
                bubbles: true,
                composed: true
            }));
        }
    }

    handleMouseEnter() {
        this.dispatchEvent(new CustomEvent('seathover', {
            detail: { seatId: this.seat.id },
            bubbles: true,
            composed: true
        }));
    }

    handleMouseLeave() {
        this.dispatchEvent(new CustomEvent('seatleave', {
            bubbles: true,
            composed: true
        }));
    }

    get seatClasses() {
        let classes = `seat ${this.seat.seatClass}`;
        if (this.showHeatMap && this.seat.isAvailable) {
            classes += ' heat-map-seat';
        }
        return classes;
    }

    get containerClasses() {
        return `seat-container ${this.seat.computedClass || this.seat.seatClass}`;
    }

    get seatStyle() {
        return this.seat.heatMapStyle || '';
    }

    get dataAttributes() {
        return {
            'data-available': this.seat.isAvailable,
            'data-selected': this.seat.isSelected,
            'data-position': this.seat.position
        };
    }
}