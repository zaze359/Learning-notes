

```xml
<androidx.constraintlayout.widget.Guideline
    android:id="@+id/beginLine"
    android:layout_width="wrap_content"
    android:layout_height="wrap_content"
    android:orientation="vertical"
    app:layout_constraintGuide_begin="@dimen/dp_40" />

<androidx.constraintlayout.widget.Guideline
    android:id="@+id/endLine"
    android:layout_width="wrap_content"
    android:layout_height="wrap_content"
    android:orientation="vertical"
    app:layout_constraintGuide_end="@dimen/dp_40" />
```



```xml
<TextView
    android:id="@+id/contentTv"
    android:layout_width="match_parent"
    android:layout_height="@dimen/dp_180"
    android:gravity="center_vertical"
    android:paddingLeft="@dimen/dp_40"
    android:paddingRight="@dimen/dp_40"
    app:layout_constraintLeft_toLeftOf="parent"
    app:layout_constraintRight_toRightOf="parent"
    app:layout_constraintTop_toTopOf="parent" />

<androidx.constraintlayout.widget.Barrier
    android:id="@+id/messageTextDialogBarrier"
    android:layout_width="wrap_content"
    android:layout_height="wrap_content"
    app:barrierDirection="bottom"
    app:constraint_referenced_ids="contentTv" />
```

```xml
<androidx.constraintlayout.widget.Group
    android:id="@+id/viewGroup"
    android:layout_width="wrap_content"
    android:layout_height="wrap_content"
    android:visibility="gone"
		app:constraint_referenced_ids="view1,view2" />
```



```
app:layout_constraintWidth_default="percent"
app:layout_constraintWidth_percent="0.2"
```

