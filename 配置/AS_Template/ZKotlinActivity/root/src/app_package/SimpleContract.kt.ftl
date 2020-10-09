package ${packageName}.contract

import ${corePackageName}.${baseViewName}

/**
 * Description : 
 * @author : ${author}
 * @version : ${.now?string("yyyy-MM-dd hh:mm")} 1.0
 */
interface ${contractInterface} {

	interface View : ${baseViewName} {

	}

	interface Presenter : ${basePresenterName}<View> {
		
	}

}
