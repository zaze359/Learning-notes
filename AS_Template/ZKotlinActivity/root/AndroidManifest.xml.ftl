<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools"
    package="${packageName}">
    
    <application>
        <activity android:name="${packageName}.ui.${activityClass}"
            android:screenOrientation="portrait"
            android:theme="@style/AppTheme" />
    </application>
</manifest>
