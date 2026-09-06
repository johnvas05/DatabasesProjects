import com.travelagency.*;

import javafx.application.Application;
import javafx.application.Platform;
import javafx.scene.Node;
import javafx.scene.Parent;
import javafx.scene.control.CheckBox;
import javafx.scene.control.ComboBoxBase;
import javafx.scene.control.Label;
import javafx.scene.control.ScrollPane;
import javafx.scene.control.Tab;
import javafx.scene.control.TabPane;
import javafx.scene.control.TableView;
import javafx.scene.control.TextArea;
import javafx.scene.control.TextField;
import javafx.scene.control.TextInputControl;
import javafx.scene.layout.HBox;
import javafx.stage.Stage;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.function.Supplier;

/**
 * =====================================================================
 * Label check for every screen of the GUI (spec 3.2.2).
 * =====================================================================
 *
 * Builds each screen, walks its scene graph and reports every input control
 * (text field, drop-down, date picker, check box) that has no label next to
 * it. A form the user cannot read is a form the user cannot fill in, so this
 * is checked the same way as the rest of the behaviour.
 *
 * The window is never shown; the screens are only built and inspected.
 *
 * Run through tests/ui_tests.sh (it puts JavaFX on the class path).
 */
public class UiLabelTests {

    public static void main(String[] args) {
        // launched from a plain class, so JavaFX also starts from the class path
        Application.launch(Checker.class, args);
    }

    public static class Checker extends Application {

        private int passed = 0;
        private int failed = 0;

        @Override
        public void start(Stage stage) {
            System.out.println("Label check for every screen (3.2.2)");

            Map<String, Supplier<Parent>> screens = new LinkedHashMap<>();
            screens.put("Customers", () -> new CustomerView().getView());
            screens.put("Vehicles", () -> new VehicleView().getView());
            screens.put("Lodgings", () -> new LodgingView().getView());
            screens.put("Trips", () -> new TripView().getView());
            screens.put("Reservations", () -> new ReservationView().getView());
            screens.put("Staff", () -> new WorkerView().getView());
            screens.put("Admin & Logs", () -> new AdminView().getView());
            screens.put("Universal Manager", UniversalTableView::new);

            selfCheck();

            System.out.println();
            for (Map.Entry<String, Supplier<Parent>> screen : screens.entrySet()) {
                check(screen.getKey(), screen.getValue());
            }

            System.out.println();
            System.out.println("Passed: " + passed + "   Failed: " + failed);
            Platform.exit();
            System.exit(failed == 0 ? 0 : 1);
        }

        /**
         * The check has to be able to fail, otherwise a green run means nothing:
         * a bare field must be reported, a labelled one must not.
         */
        private void selfCheck() {
            System.out.println();
            HBox bare = new HBox(new TextField());
            List<Node> found = new ArrayList<>();
            collectInputs(bare, found);
            boolean detectsMissing = found.size() == 1 && !hasLabel(found.get(0));

            HBox labelled = new HBox(new Label("Name"), new TextField());
            found.clear();
            collectInputs(labelled, found);
            boolean acceptsLabelled = found.size() == 1 && hasLabel(found.get(0));

            if (detectsMissing && acceptsLabelled) {
                passed++;
                System.out.println("  ok   the check itself reports a field without a label");
            } else {
                failed++;
                System.out.println("  FAIL the check is broken: reports-missing=" + detectsMissing
                        + ", accepts-labelled=" + acceptsLabelled);
            }
        }

        private void check(String name, Supplier<Parent> builder) {
            Parent view;
            try {
                view = builder.get();
            } catch (Exception e) {
                failed++;
                System.out.println("  FAIL " + name + " could not be built: " + e);
                return;
            }

            List<Node> inputs = new ArrayList<>();
            collectInputs(view, inputs);

            List<String> unlabelled = new ArrayList<>();
            for (Node input : inputs) {
                if (!hasLabel(input)) {
                    unlabelled.add(describe(input));
                }
            }

            if (inputs.isEmpty()) {
                passed++;
                System.out.println("  ok   " + name + " (no input controls)");
            } else if (unlabelled.isEmpty()) {
                passed++;
                System.out.println("  ok   " + name + " (" + inputs.size() + " inputs, all labelled)");
            } else {
                failed++;
                System.out.println("  FAIL " + name + ": " + unlabelled.size() + " of " + inputs.size()
                        + " inputs have no label");
                for (String control : unlabelled) {
                    System.out.println("       - " + control);
                }
            }
        }

        /** Every control the user types into or picks from, tables excluded. */
        private void collectInputs(Node node, List<Node> found) {
            if (node instanceof TableView<?>) {
                return; // the cells of a table are not form inputs
            }
            if (node instanceof TextArea area && !area.isEditable()) {
                return; // read-only output, e.g. the trip details panels
            }
            if (node instanceof TextInputControl || node instanceof ComboBoxBase<?> || node instanceof CheckBox) {
                found.add(node);
                return; // do not look inside a control
            }
            if (node instanceof TabPane tabs) {
                // the content of a tab is not a child of the TabPane until it is
                // shown, so walk the tabs themselves
                for (Tab tab : tabs.getTabs()) {
                    if (tab.getContent() != null) {
                        collectInputs(tab.getContent(), found);
                    }
                }
                return;
            }
            if (node instanceof ScrollPane scroll) {
                if (scroll.getContent() != null) {
                    collectInputs(scroll.getContent(), found);
                }
                return;
            }
            if (node instanceof Parent parent) {
                for (Node child : parent.getChildrenUnmodifiable()) {
                    collectInputs(child, found);
                }
            }
        }

        /**
         * A control is labelled when a Label sits before it in the same box -
         * the layout Forms.field() builds, and the layout the hand-written rows
         * of the Universal Manager use.
         */
        private boolean hasLabel(Node input) {
            Parent parent = input.getParent();
            if (parent == null) {
                return false;
            }
            List<Node> siblings = parent.getChildrenUnmodifiable();
            int index = siblings.indexOf(input);
            for (int i = index - 1; i >= 0; i--) {
                if (siblings.get(i) instanceof Label label) {
                    return !label.getText().isBlank();
                }
            }
            // a control wrapped in one more box, e.g. the date + hour pair
            return parent.getParent() != null && hasLabel(parent);
        }

        private String describe(Node input) {
            String type = input.getClass().getSimpleName();
            String hint = "";
            if (input instanceof TextField field) {
                hint = field.getPromptText();
            } else if (input instanceof ComboBoxBase<?> combo) {
                hint = combo.getPromptText();
            } else if (input instanceof CheckBox box) {
                hint = box.getText();
            }
            return type + (hint == null || hint.isBlank() ? "" : " (\"" + hint + "\")");
        }
    }
}
