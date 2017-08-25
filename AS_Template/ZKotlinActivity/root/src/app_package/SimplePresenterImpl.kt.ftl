package ${packageName}.presenter.impl

import ${packageName}.presenter.${presenterInterface}
import ${corePackageName}.${basePresenterName}
import ${packageName}.view.${viewInterface}

/**
 * Description :
 * @author : ${author}
 * @version : ${.now?string("yyyy-MM-dd hh:mm")} 1.0
 */
open class ${presenterImpl}(view: ${viewInterface}) : ${basePresenterName}<${viewInterface}>(view), ${presenterInterface} {
	
}
