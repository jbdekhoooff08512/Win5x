import React, { createContext, useContext, useState, ReactNode, useCallback, useEffect } from 'react';

interface BettingWarningContextType {
  hasActiveBets: boolean;
  setHasActiveBets: (hasBets: boolean) => void;
  currentRoundId: string | null;
  setCurrentRoundId: (roundId: string | null) => void;
  showWarning: boolean;
  setShowWarning: (show: boolean) => void;
  pendingNavigation: string | null;
  setPendingNavigation: (path: string | null) => void;
  confirmNavigation: () => void;
  cancelNavigation: () => void;
  resetBettingState: () => void;
}

const BettingWarningContext = createContext<BettingWarningContextType | undefined>(undefined);

interface BettingWarningProviderProps {
  children: ReactNode;
}

export function BettingWarningProvider({ children }: BettingWarningProviderProps) {
  const [hasActiveBets, setHasActiveBets] = useState(false);
  const [currentRoundId, setCurrentRoundId] = useState<string | null>(null);
  const [showWarning, setShowWarning] = useState(false);
  const [pendingNavigation, setPendingNavigation] = useState<string | null>(null);

  // Add beforeunload event listener to prevent accidental browser close
  useEffect(() => {
    const handleBeforeUnload = (e: BeforeUnloadEvent) => {
      if (hasActiveBets) {
        e.preventDefault();
        e.returnValue = 'You have an active bet. Are you sure you want to leave? You will lose your bet amount.';
        return e.returnValue;
      }
    };

    window.addEventListener('beforeunload', handleBeforeUnload);

    return () => {
      window.removeEventListener('beforeunload', handleBeforeUnload);
    };
  }, [hasActiveBets]);

  const confirmNavigation = useCallback(() => {
    setShowWarning(false);
    setPendingNavigation(null);
    setHasActiveBets(false);
    setCurrentRoundId(null);
    
    // Navigate to the pending path
    if (pendingNavigation) {
      window.location.assign(pendingNavigation);
    }
  }, [pendingNavigation]);

  const cancelNavigation = useCallback(() => {
    setShowWarning(false);
    setPendingNavigation(null);
  }, []);

  const resetBettingState = useCallback(() => {
    setHasActiveBets(false);
    setCurrentRoundId(null);
    setShowWarning(false);
    setPendingNavigation(null);
  }, []);

  const value: BettingWarningContextType = {
    hasActiveBets,
    setHasActiveBets,
    currentRoundId,
    setCurrentRoundId,
    showWarning,
    setShowWarning,
    pendingNavigation,
    setPendingNavigation,
    confirmNavigation,
    cancelNavigation,
    resetBettingState,
  };

  return (
    <BettingWarningContext.Provider value={value}>
      {children}
    </BettingWarningContext.Provider>
  );
}

export function useBettingWarning() {
  const context = useContext(BettingWarningContext);
  if (context === undefined) {
    throw new Error('useBettingWarning must be used within a BettingWarningProvider');
  }
  return context;
}
