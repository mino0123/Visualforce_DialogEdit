public class DialogEditParameters {
    public SObjectField[] fields { get; set; }
    public SObject record { get; set; }
    public DialogEdit.CancelEvent onCancel { get; private set; }
    public DialogEdit.AfterSaveEvent onSaved { get; private set; }
    public DialogEdit.SaveErrorEvent onSaveError { get; private set; }
    {
        onCancel = new DialogEdit.CancelEvent();
        onSaved = new DialogEdit.AfterSaveEvent();
        onSaveError = new DialogEdit.SaveErrorEvent();
    }
}