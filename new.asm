START:
	STORE R1, 10
	STORE R2, 20
	DPR R1
	DPR R2
	IF R1, 10, SKIP
	ADD R1, R2, 5
SKIP:
	DPR R1
	EXIT
