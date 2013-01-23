function clientTaskCompleted(task,eventdata)
   disp(['Started at ' task.StartTime ' Ended at ' task.FinishTime ' Finished task: ' num2str(task.ID)])