public class DialogEditPage {

    public Row[] rows { get; private set; }
    RowAdder rowAdder = new RowAdder(this);
    public DialogEditParameters dialogEditParameters { get; set; }
    public static SObjectField[] FIELDS { get; private set; }
    static {
        FIELDS = new SObjectField[] {
            Account.SObjectType.Name,
            Account.SObjectType.Type,
            Account.SObjectType.ParentId,
            Account.SObjectType.Phone,
            Account.SObjectType.Fax,
            Account.SObjectType.TickerSymbol,
            Account.SObjectType.BillingPostalCode,
            Account.SObjectType.BillingState,
            Account.SObjectType.BillingCity,
            Account.SObjectType.BillingStreet,
            Account.SObjectType.Description
        };
    }

    public DialogEditPage() {
        rows = new Row[]{};
        Account[] records = [
            SELECT
                Name,
                Type,
                ParentId,
                Phone,
                Fax,
                TickerSymbol,
                BillingPostalCode,
                BillingState,
                BillingCity,
                BillingStreet,
                Description
            FROM Account
            ORDER BY LastModifiedDate DESC
            LIMIT 30
        ];
        for (Account r : records) {
            rowAdder.add(r);
        }
        dialogEditParameters = new DialogEditParameters();
    }

    class RowAdder extends Bridge {
        RowEventListener onEdit;
        RowEventListener onCloneEdit;
        RowAdder(DialogEditPage page) {
            super(page);
            onEdit = new EditDialogInitializer(page);
            onCloneEdit = new CloneDialogInitializer(page);
        }
        public void add(Account r) {
            Row row = new Row(r);
            row.onEdit = onEdit;
            row.onCloneEdit = onCloneEdit;
            page.rows.add(row);
        }
        public void addTop(Account r) {
            Row row = new Row(r);
            row.onEdit = onEdit;
            row.onCloneEdit = onCloneEdit;
            Row[] rows = page.rows;
            if (rows.size() > 0) {
                rows.add(0, row);
            } else {
                rows.add(row);
            }
        }
    }

    public void newDialogRecord() {
        NewDialogInitializer initializer = new NewDialogInitializer(this);
        initializer.run();
    }

    abstract class Bridge {
        protected DialogEditPage page { get; private set; }
        protected Bridge(DialogEditPage page) {
            if (page == null) {
                throw new NullPointerException();
            }
            this.page = page;
        }
    }

    public class Row {
        public Account record { get; set; }
        public RowEventListener onEdit { get; set; }
        public RowEventListener onCloneEdit { get; set; }
        public Row(Account record) {
            this.record = record;
        }
        public void edit() {
            onEdit.run(record);
        }
        public void cloneEdit() {
            onCloneEdit.run(record.clone());
        }
    }

    interface RowEventListener {
        void run(Account record);
    }

    class NewDialogInitializer extends Bridge {
        public NewDialogInitializer(DialogEditPage page) {
            super(page);
        }
        public void run() {
            DialogEditParameters dialogEditParameters = new DialogEditParameters();
            dialogEditParameters.fields = FIELDS;
            dialogEditParameters.record = new Account();
            DialogDestructor destructor = new DialogDestructor(page);
            dialogEditParameters.onCancel.add(destructor);
            dialogEditParameters.onSaved.add(new AddSavedRow(page));
            dialogEditParameters.onSaved.add(destructor);
            dialogEditParameters.onSaved.add(new DialogSavedValuesTranslator(FIELDS));
            page.dialogEditParameters = dialogEditParameters;
        }
    }

    class EditDialogInitializer extends Bridge implements RowEventListener {
        public EditDialogInitializer(DialogEditPage page) {
            super(page);
        }
        public void run(Account record) {
            DialogEditParameters dialogEditParameters = new DialogEditParameters();
            dialogEditParameters.fields = FIELDS;
            dialogEditParameters.record = record;
            DialogDestructor destructor = new DialogDestructor(page);
            dialogEditParameters.onCancel.add(destructor);
            dialogEditParameters.onSaved.add(destructor);
            dialogEditParameters.onSaved.add(new DialogSavedValuesTranslator(FIELDS));
            page.dialogEditParameters = dialogEditParameters;
        }
    }

    class CloneDialogInitializer extends Bridge implements RowEventListener {
        public CloneDialogInitializer(DialogEditPage page) {
            super(page);
        }
        public void run(Account record) {
            DialogEditParameters dialogEditParameters = new DialogEditParameters();
            dialogEditParameters.fields = FIELDS;
            dialogEditParameters.record = record.clone();
            DialogDestructor destructor = new DialogDestructor(page);
            dialogEditParameters.onCancel.add(destructor);
            dialogEditParameters.onSaved.add(new AddSavedRow(page));
            dialogEditParameters.onSaved.add(destructor);
            dialogEditParameters.onSaved.add(new DialogSavedValuesTranslator(FIELDS));
            page.dialogEditParameters = dialogEditParameters;
        }
    }

    class DialogDestructor extends Bridge implements DialogEdit.CancelListener, DialogEdit.AfterSaveListener {
        DialogDestructor(DialogEditPage page) {
            super(page);
        }
        public void run(SObject saved, SObject origin) {
            run();
        }
        public void run() {
            page.dialogEditParameters = null;
        }
    }

    class DialogSavedValuesTranslator implements DialogEdit.AfterSaveListener {
        SObjectField[] fieldList;
        public DialogSavedValuesTranslator(SObjectField[] fieldList) {
            this.fieldList = fieldList;
        }
        public void run(SObject edit, SObject original) {
            // translate saved values to original
            for (SObjectField f : fieldList) {
                if (f.getDescribe().isUpdateable()) {
                    original.put(f, edit.get(f));
                }
            }
        }
    }

    class AddSavedRow extends Bridge implements DialogEdit.AfterSaveListener {
        public AddSavedRow(DialogEditPage page) {
            super(page);
        }
        public void run(SObject edit, SObject original) {
            page.rowAdder.addTop((Account) edit);
        }
    }

}