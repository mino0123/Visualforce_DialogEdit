public class DialogEdit {

    public SObjectField[] fields { get; private set; }
    private SObject origin { get; set; }
    public SObject dialogRecord { get; private set; }

    public CancelEvent onCancel { get; private set; }
    public AfterSaveEvent onSaved { get; private set; }
    public SaveErrorEvent onSaveError { get; private set; }

    public DialogEditParameters parameters { get; set {
        if (value == null || dialogRecord != null) {
            return;
        }
        fields = value.fields;
        origin = value.record;
        dialogRecord = (origin == null ? null : origin.clone(true));
        onCancel = value.onCancel;
        onSaved = value.onSaved;
        onSaveError = value.onSaveError;
    }}

    private void clearParameters() {
        fields = null;
        origin = null;
        dialogRecord = null;
        onCancel = null;
        onSaved = null;
        onSaveError = null;
    }

    public void save() {
        try {
            System.debug(dialogRecord);
            upsert dialogRecord;
            onSaved.run(dialogRecord, origin);
            clearParameters();
        } catch (DMLException e) {
            onSaveError.run(dialogRecord, e);
        }
    }

    public void cancel() {
        onCancel.run();
        clearParameters();
    }

    public class CancelEvent {
        CancelListener[] listeners;
        public CancelEvent() {
            this.listeners = new CancelListener[0];
        }
        public void add(CancelListener listener) {
            listeners.add(listener);
        }
        public void run() {
            for (CancelListener l : listeners) {
                l.run();
            }
        }
    }
    public class AfterSaveEvent {
        AfterSaveListener[] listeners;
        public AfterSaveEvent() {
            this.listeners = new AfterSaveListener[0];
        }
        public void add(AfterSaveListener listener) {
            listeners.add(listener);
        }
        public void run(SObject saved, SObject origin) {
            for (AfterSaveListener l : listeners) {
                l.run(saved, origin);
            }
        }
    }
    public class SaveErrorEvent {
        SaveErrorEventListener[] listeners;
        public SaveErrorEvent() {
            this.listeners = new SaveErrorEventListener[0];
        }
        public void add(SaveErrorEventListener listener) {
            listeners.add(listener);
        }
        public void run(SObject record, DMLException error) {
            for (SaveErrorEventListener l : listeners) {
                l.run(record, error);
            }
        }
    }

    public interface CancelListener {
        void run();
    }
    public interface AfterSaveListener {
        void run(SObject saved, SObject origin);
    }
    public interface SaveErrorEventListener {
        void run(SObject record, DMLException error);
    }

}