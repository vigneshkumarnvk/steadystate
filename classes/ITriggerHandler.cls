/*
Added By : Harika Madapathi
Dated    : 07/22/2023
Summary  : Trigger framework interface that defines structure for trigger handler classes
* Modification Log :
 * Developer                 Date                   Description
 * ----------------------------------------------------------------------------                 
 * Harika Madapathi         07/22/2023             68128 - Tech Debt: Update Trigger Framework for SalesOrder object
*************************************************************************************************************/
public interface ITriggerHandler {
	 //method executed for first entry into trigger context
	 void mainEntry();
	 //logic to be executed on second and so on entries into trigger are defined here
	 void inProgressEntry();
	 //any DMLs are issued here
	 void updateObjects();

}