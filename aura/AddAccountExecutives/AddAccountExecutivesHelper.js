({
	openPrompt: function(cmp, event) {
                    this.LightningPrompt.open({
                        message: 'this is the prompt message',
                        variant: 'headerless',
                        label: 'Please Respond',
                        defaultValue: 'default input value',
                    }).then(function(result) {
                        // result is input value if clicked "OK"
                        // result is null if clicked "Cancel"
                        console.log('prompt result is', result);
                    });
                }
})