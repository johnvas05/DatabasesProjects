package com.travelagency;

import javafx.geometry.Insets;
import javafx.geometry.Pos;
import javafx.scene.Node;
import javafx.scene.control.Label;
import javafx.scene.layout.FlowPane;
import javafx.scene.layout.Region;
import javafx.scene.layout.VBox;

/**
 * Small helpers so every input of the GUI carries a visible label (3.2.2) and
 * the forms wrap instead of being cut off when the window is narrow.
 *
 * The insert/update dialog of the Universal Manager builds its own labels from
 * the schema; these helpers are for the hand-written screens.
 */
final class Forms {

    /** Width used when a control does not ask for one itself. */
    private static final double DEFAULT_WIDTH = 150;

    private Forms() {
        // helper class
    }

    /** A labelled input: a small caption above the control. */
    static VBox field(String label, Node control) {
        Label caption = new Label(label);
        caption.setStyle("-fx-font-size: 11px; -fx-text-fill: #555555;");
        if (control instanceof Region region && region.getPrefWidth() <= 0) {
            region.setPrefWidth(DEFAULT_WIDTH);
        }
        return new VBox(3, caption, control);
    }

    /** A labelled input of a given width, for long values such as a full name. */
    static VBox field(String label, Region control, double width) {
        control.setPrefWidth(width);
        return field(label, (Node) control);
    }

    /**
     * A button placed in a row of labelled inputs: the blank caption keeps it
     * aligned with the controls next to it.
     */
    static VBox action(Node button) {
        Label spacer = new Label(" ");
        spacer.setStyle("-fx-font-size: 11px;");
        VBox box = new VBox(3, spacer, button);
        box.setAlignment(Pos.BOTTOM_LEFT);
        return box;
    }

    /** A row of labelled inputs that wraps instead of being cut off. */
    static FlowPane row(Node... fields) {
        FlowPane pane = new FlowPane(12, 8, fields);
        pane.setPadding(new Insets(4, 0, 4, 0));
        return pane;
    }
}
