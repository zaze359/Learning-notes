package ${packageName}.presenter

import ${packageName}.contract.${contractInterface}
import ${mvpPackageName}.${mvpPresenterName}

/**
 * Description :
 * @author : ${author}
 * @version : ${.now?string("yyyy-MM-dd hh:mm")} 1.0
 */
class ${presenter}(view : ${contractInterface}.View) : ${mvpPresenterName}<${contractInterface}.View>(view) , ${contractInterface}.Presenter {
	
}
